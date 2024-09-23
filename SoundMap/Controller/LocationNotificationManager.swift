//
//  LocationNotificationManager.swift
//  SoundMap
//
//  Created by Jonathan on 06/09/2024.
//

import Foundation
import CoreLocation
import UserNotifications
import GooglePlaces

struct IgnoredLocation: Codable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
    }
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}


class LocationNotificationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationNotificationManager()
    
    private let locationManager: CLLocationManager
    private let notificationCenter = UNUserNotificationCenter.current()
    private let placesClient = GMSPlacesClient.shared()
    
    private var isMonitoring = false
    private var lastSignificantLocation: CLLocation?
    private var stayStartTime: Date?
    private var notifiedVenues: [String: Date] = [:]
    private var frequentlyVisitedVenues: [String: Int] = [:]
    private var ignoredLocations: [IgnoredLocation] = []
    private var lastNotificationTime: Date?
    private var oneTimeLocationCompletion: ((Result<CLLocation, Error>) -> Void)?
    
    private let minimumUpdateInterval: TimeInterval = 300 // 5 minutes for background app fetches
    private var lastUpdateTime: Date?
    
    private let minimumStayDuration: TimeInterval = 300 // 5 minutes
    private let maxDailyNotifications: Int = 5
    private let speedThreshold: CLLocationSpeed = 2.0 // m/s, roughly walking speed
    private let venueCooldown: TimeInterval = 86400 // 1 day cooldown per venue
    private let notificationCooldown: TimeInterval = 3600 // 1 hour between notifications
    private let frequentVisitThreshold: Int = 3 // Number of visits to consider a venue as frequently visited
    private let ignoreRadius: CLLocationDistance = 50 // 50 meters
    private let significantDistance: CLLocationDistance = 50 // 50 meters to be considered a significant move
    
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.distanceFilter = 100 // Update every 100 meters
        
        loadPersistedData()
    }
    
    
    func configure() {
        // This method can be used for any additional setup if needed
        requestLocationPermissions()
        requestNotificationPermissions()
    }
    
    func requestLocationPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startMonitoring() {
        isMonitoring = true
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            print("Always authorization granted")
            startContinuousLocationUpdates()
        case .authorizedWhenInUse:
            print("When in use authorization granted")
            locationManager.requestAlwaysAuthorization()
        case .notDetermined:
            print("Location authorization not determined")
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            print("Location access is restricted or denied")
            stopMonitoring()
        @unknown default:
            print("Unknown authorization status")
            stopMonitoring()
        }
    }
    
    func checkNotificationPermissions() {
        notificationCenter.getNotificationSettings { settings in
            print("Notification settings: \(settings)")
        }
    }
    
    private func startContinuousLocationUpdates() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        print("Continuous location updates started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        locationManager.stopUpdatingLocation()
        print("Location monitoring stopped")
    }
    
    func requestOneTimeLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        oneTimeLocationCompletion = completion
        locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isMonitoring, let location = locations.last else { return }
        
        let currentTime = Date()
        if let lastUpdate = lastUpdateTime,
           currentTime.timeIntervalSince(lastUpdate) < minimumUpdateInterval {
            // Skip this update if it's too soon after the last one
            return
        }
        
        processLocationUpdate(location)
        lastUpdateTime = currentTime
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        if let completion = oneTimeLocationCompletion {
            completion(.failure(error))
            oneTimeLocationCompletion = nil
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    // MARK: - Google Places API Methods
    
    private func processLocationUpdate(_ location: CLLocation) {
        // Check if enough time has passed since the last notification
        if let lastTime = lastNotificationTime, Date().timeIntervalSince(lastTime) < notificationCooldown {
            return
        }
        
        // Check if the user is moving too fast
        if location.speed > speedThreshold {
            resetStayData()
            return
        }
        
        // Check if this is a significant move from the last recorded location
        if let lastLocation = lastSignificantLocation,
           location.distance(from: lastLocation) > significantDistance {
            resetStayData()
            lastSignificantLocation = location
            stayStartTime = Date()
            return
        }
        
        // If this is the first update or after a reset
        if lastSignificantLocation == nil {
            lastSignificantLocation = location
            stayStartTime = Date()
            return
        }
        
        // Check if the user has been in the same location for long enough
        if let startTime = stayStartTime,
           Date().timeIntervalSince(startTime) >= minimumStayDuration {
            checkNearbyPlaces(location: location)
            // Reset after checking to prevent repeated checks
            resetStayData()
        }
    }
    
    private func resetStayData() {
        lastSignificantLocation = nil
        stayStartTime = nil
    }
    
    
    func checkNearbyPlaces(location: CLLocation? = nil, completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        let locationToUse = location ?? locationManager.location
        
        guard let currentLocation = locationToUse else {
            completion?(.noData)
            return
        }
        
        // First, check if the current location is within any ignored location's radius
        for ignoredLocation in ignoredLocations {
            let ignoredCoordinate = ignoredLocation.coordinate
            let ignoredLocation = CLLocation(latitude: ignoredCoordinate.latitude, longitude: ignoredCoordinate.longitude)
            if currentLocation.distance(from: ignoredLocation) <= ignoreRadius {
                // User is within an ignored location, don't proceed
                completion?(.noData)
                return
            }
        }
        
        let placeTypes = ["restaurant", "cafe", "bar"]
        
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        filter.locationRestriction = GMSPlaceRectangularLocationOption(
            CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude - 0.001, longitude: currentLocation.coordinate.longitude - 0.001),
            CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude + 0.001, longitude: currentLocation.coordinate.longitude + 0.001)
        )
        
        print("Making request to Google Places API: findPlaceLikelihoodsFromCurrentLocation")
        
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: [.name, .placeID, .types]) { [weak self] (placeLikelihoods, error) in
            guard let self = self else {
                completion?(.failed)
                return
            }
            
            if let error = error {
                print("Error finding nearby places: \(error.localizedDescription)")
                completion?(.failed)
                return
            }
            
            if let placeLikelihood = placeLikelihoods?.first,
               let placeType = placeLikelihood.place.types?.first,
               placeTypes.contains(placeType) {
                self.handleDetectedPlace(placeLikelihood.place)
                completion?(.newData)
            } else {
                completion?(.noData)
            }
        }
    }
    
    private func handleDetectedPlace(_ place: GMSPlace) {
        guard let placeId = place.placeID else { return }
        
        // Increment visit count for this venue
        frequentlyVisitedVenues[placeId, default: 0] += 1
        print("frequentlyVisitedVenues:", frequentlyVisitedVenues)
        
        // Check if this is a frequently visited venue
        if frequentlyVisitedVenues[placeId, default: 0] >= frequentVisitThreshold {
            // Don't send notification for frequently visited venues
            return
        }
        
        print("NotifiedVenues:", notifiedVenues)
        
        // Check if we've already notified about this venue recently
        if let lastNotificationDate = notifiedVenues[placeId],
           Date().timeIntervalSince(lastNotificationDate) < venueCooldown {
            return
        }
        
        // Check if we've reached the daily notification limit
        if notifiedVenues.count >= maxDailyNotifications {
            print("Daily notification limit reached")
            return
        }
        
        // This is a new venue or we haven't notified about it recently
        sendNotification(for: place)
        
        persistData()
    }
    
    private func sendNotification(for place: GMSPlace) {
        guard notifiedVenues.count < maxDailyNotifications,
              let placeId = place.placeID else {
            print("Daily notification limit reached or invalid place")
            return
        }
        
        let title = "New Venue Detected"
        let body = "Are you at \(place.name ?? "a new venue")? Would you like to record the noise level?"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["placeId": placeId]
        
        // Create a trigger for immediate presentation
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        print("Attempting to send notification for place: \(place.name ?? "Unknown"), ID: \(placeId)")
        
        self.notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                self.notifiedVenues[placeId] = Date()
                self.lastNotificationTime = Date()
                self.resetStayData()
                print("Notification request added successfully for place: \(place.name ?? "Unknown")")
                
                // Check pending notifications
                self.notificationCenter.getPendingNotificationRequests { requests in
                    print("Pending notification requests: \(requests.count)")
                }
                
                // Check notification settings
                self.notificationCenter.getNotificationSettings { settings in
                    print("Notification settings: \(settings)")
                }
            }
        }
    }
    
    // MARK: - Ignored Locations Management
    
    func addIgnoredLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let newLocation = IgnoredLocation(name: name, coordinate: coordinate)
        ignoredLocations.append(newLocation)
        persistData()
    }
    
    func removeIgnoredLocation(withId id: UUID) {
        ignoredLocations.removeAll { $0.id == id }
        persistData()
    }
    
    func getIgnoredLocations() -> [IgnoredLocation] {
        return ignoredLocations
    }
    
    // MARK: - Data Persistence
    
    private func persistData() {
        let defaults = UserDefaults.standard
        defaults.set(frequentlyVisitedVenues, forKey: "FrequentlyVisitedVenues")
        
        if let encodedIgnoredLocations = try? JSONEncoder().encode(ignoredLocations) {
            defaults.set(encodedIgnoredLocations, forKey: "IgnoredLocations")
        }
    }
    
    private func loadPersistedData() {
        let defaults = UserDefaults.standard
        frequentlyVisitedVenues = defaults.object(forKey: "FrequentlyVisitedVenues") as? [String: Int] ?? [:]
        
        if let savedIgnoredLocations = defaults.object(forKey: "IgnoredLocations") as? Data,
           let decodedIgnoredLocations = try? JSONDecoder().decode([IgnoredLocation].self, from: savedIgnoredLocations) {
            ignoredLocations = decodedIgnoredLocations
        }
    }
    
    // MARK: - Notification Methods
    
    func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotifications() {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(86400)
        
        notifiedVenues.removeAll()
        
        let timer = Timer(fire: endOfDay, interval: 0, repeats: false) { [weak self] _ in
            self?.resetDailyNotifications()
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
