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
    
    private let minimumUpdateInterval: TimeInterval = 30 // 30 seconds for background app fetches
    private var lastUpdateTime: Date?
    
    private let minimumStayDuration: TimeInterval = 180 // 3 minutes
    private let maxDailyNotifications: Int = 5
    private let speedThreshold: CLLocationSpeed = 2.0 // m/s, roughly walking speed
    private let venueCooldown: TimeInterval = 86400 // 1 day cooldown per venue
    private let notificationCooldown: TimeInterval = 3600 // 1 hour between notifications
    private let frequentVisitThreshold: Int = 3 // Number of visits to consider a venue as frequently visited
    private let ignoreRadius: CLLocationDistance = 50// 50 meters
    private let significantDistance: CLLocationDistance = 25 // 25 meters to be considered a significant move
    
    private let logger = NotificationLogger.shared
    
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10  // Update every 10 meters instead of kCLDistanceFilterNone
        
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
        locationManager.pausesLocationUpdatesAutomatically = false
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
        guard isMonitoring else {
            logger.log(.location, "Location update skipped - monitoring disabled")
            return
        }
        
        guard let location = locations.last, location.horizontalAccuracy <= 65 else {
            logger.log(.location, "Location update skipped - poor accuracy")
            return
        }
        
        let currentTime = Date()
        if let lastUpdate = lastUpdateTime {
            let timeSince = currentTime.timeIntervalSince(lastUpdate)
            if timeSince < minimumUpdateInterval {
                logger.log(.location, "Location update skipped - too soon (\(Int(timeSince))s < \(minimumUpdateInterval)s)")
                return
            }
        }
        
        logger.log(.location, """
            📍 Processing location update:
            - Accuracy: \(location.horizontalAccuracy)m
            - Speed: \(location.speed)m/s
            - Time since last: \(lastUpdateTime.map { currentTime.timeIntervalSince($0) } ?? 0)s
            """)
        
        processLocationUpdate(location)
        lastUpdateTime = currentTime
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.log(.error, "Location error: \(error.localizedDescription)")
        
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                stopMonitoring()
                logger.log(.error, "Location permissions denied")
            case .locationUnknown:
                // Temporary error - keep monitoring
                logger.log(.error, "Location temporarily unavailable")
            case .network:
                // Network-related error
                logger.log(.error, "Network-related location error")
            default:
                logger.log(.error, "Other location error: \(error.code)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            // Enable background location updates
            locationManager.allowsBackgroundLocationUpdates = true
            startContinuousLocationUpdates()
        case .authorizedWhenInUse:
            // Disable background updates but keep monitoring in foreground
            locationManager.allowsBackgroundLocationUpdates = false
            startContinuousLocationUpdates()
        default:
            stopMonitoring()
        }
    }
    
    // MARK: - Google Places API Methods
    
    private func processLocationUpdate(_ location: CLLocation) {
        let logger = NotificationLogger.shared
        logger.log(.location, "Processing new location update: \(location.coordinate)")
        
        // Check notification cooldown
        if let lastTime = lastNotificationTime, Date().timeIntervalSince(lastTime) < notificationCooldown {
            logger.log(.notification, "Skipping due to notification cooldown. Next notification allowed in \(notificationCooldown - Date().timeIntervalSince(lastTime)) seconds")
            return
        }
        
        // Check speed
        logger.log(.location, "Current speed: \(location.speed) m/s (threshold: \(speedThreshold) m/s)")
        if location.speed > speedThreshold {
            logger.log(.location, "User moving too fast, resetting stay data")
            resetStayData()
            return
        }
        
        // Check significant movement
        if let lastLocation = lastSignificantLocation {
            let distance = location.distance(from: lastLocation)
            logger.log(.location, "Distance from last significant location: \(distance)m (threshold: \(significantDistance)m)")
            if distance > significantDistance {
                logger.log(.stay, "Significant movement detected, resetting stay timer")
                resetStayData()
                lastSignificantLocation = location
                stayStartTime = Date()
                return
            }
        }
        
        // Initialize stay tracking
        if lastSignificantLocation == nil {
            logger.log(.stay, "Initializing stay tracking at location: \(location.coordinate)")
            lastSignificantLocation = location
            stayStartTime = Date()
            return
        }
        
        // Check stay duration
        if let startTime = stayStartTime {
            let stayDuration = Date().timeIntervalSince(startTime)
            logger.log(.stay, "Current stay duration: \(stayDuration)s (threshold: \(minimumStayDuration)s)")
            if stayDuration >= minimumStayDuration {
                logger.log(.stay, "Minimum stay duration met, checking nearby places")
                checkNearbyPlaces(location: location)
                resetStayData()
            }
        }
    }
    
    private func resetStayData() {
        lastSignificantLocation = nil
        stayStartTime = nil
    }
    
    
    func checkNearbyPlaces(location: CLLocation? = nil, completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        let logger = NotificationLogger.shared
        logger.log(.venue, """
            ==========================================
            🔍 Starting Nearby Places Check
            ==========================================
            """)
        
        let locationToUse = location ?? locationManager.location
        
        guard let currentLocation = locationToUse else {
            logger.log(.error, "❌ No location available for nearby places check")
            completion?(.noData)
            return
        }
        
        logger.log(.location, """
            📍 Current Location:
            - Latitude: \(currentLocation.coordinate.latitude)
            - Longitude: \(currentLocation.coordinate.longitude)
            - Accuracy: \(currentLocation.horizontalAccuracy)m
            - Time: \(currentLocation.timestamp)
            """)
        
        // Check if the current location is within any ignored location's radius
        logger.log(.venue, "Checking \(ignoredLocations.count) ignored locations...")
        
        for ignoredLocation in ignoredLocations {
            let ignoredCoordinate = ignoredLocation.coordinate
            let ignoredLocationObj = CLLocation(latitude: ignoredCoordinate.latitude, longitude: ignoredCoordinate.longitude)
            let distance = currentLocation.distance(from: ignoredLocationObj)
            
            logger.log(.venue, """
                📍 Ignored Location Check:
                - Name: \(ignoredLocation.name)
                - Distance: \(Int(distance))m (Threshold: \(Int(ignoreRadius))m)
                """)
            
            if distance <= ignoreRadius {
                logger.log(.venue, "⛔️ Within ignored location radius, aborting venue check")
                completion?(.noData)
                return
            }
        }
        
        let placeTypes = ["restaurant", "cafe", "bar"]
        logger.log(.venue, "Looking for place types: \(placeTypes.joined(separator: ", "))")
        
        // Set up the location bounds for the search
        let searchBounds = GMSPlaceRectangularLocationOption(
            CLLocationCoordinate2D(
                latitude: currentLocation.coordinate.latitude - 0.001,
                longitude: currentLocation.coordinate.longitude - 0.001
            ),
            CLLocationCoordinate2D(
                latitude: currentLocation.coordinate.latitude + 0.001,
                longitude: currentLocation.coordinate.longitude + 0.001
            )
        )
        
        logger.log(.venue, """
            🔍 Search Parameters:
            - Search radius: ~100m (0.001 degree latitude/longitude)
            - Looking for establishments
            """)
        
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        filter.locationRestriction = searchBounds
        
        logger.log(.venue, "Making request to Google Places API...")
        
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: [.name, .placeID, .types]) { [weak self] (placeLikelihoods, error) in
            guard let self = self else {
                logger.log(.error, "❌ Self reference lost during Places API callback")
                completion?(.failed)
                return
            }
            
            if let error = error {
                logger.log(.error, """
                    ❌ Google Places API Error:
                    - Error: \(error.localizedDescription)
                    - Domain: \(error.localizedDescription)
                    """)
                completion?(.failed)
                return
            }
            
            // Log all found places
            if let places = placeLikelihoods {
                logger.log(.venue, """
                    📍 Places Found: \(places.count)
                    ==========================================
                    """)
                
                places.forEach { likelihood in
                    logger.log(.venue, """
                        Place Details:
                        - Name: \(likelihood.place.name ?? "Unknown")
                        - ID: \(likelihood.place.placeID ?? "Unknown")
                        - Types: \(likelihood.place.types?.joined(separator: ", ") ?? "None")
                        - Likelihood: \(likelihood.likelihood)
                        ------------------------------------------
                        """)
                }
            } else {
                logger.log(.venue, "No places found in the vicinity")
            }
            
            // Find the first matching place
            if let placeLikelihood = placeLikelihoods?.first,
               let place = placeLikelihoods?.first?.place,
               let placeType = place.types?.first,
               placeTypes.contains(placeType) {
                
                logger.log(.venue, """
                    ✅ Found Matching Place:
                    - Name: \(place.name ?? "Unknown")
                    - Type: \(placeType)
                    - Likelihood: \(placeLikelihood.likelihood)
                    Processing venue...
                    """)
                
                self.handleDetectedPlace(place)
                completion?(.newData)
                
            } else {
                logger.log(.venue, """
                    ℹ️ No Matching Places:
                    - Either no places found
                    - Or no places match required types: \(placeTypes.joined(separator: ", "))
                    """)
                completion?(.noData)
            }
            
            logger.log(.venue, """
                ==========================================
                🏁 Nearby Places Check Complete
                ==========================================
                """)
        }
    }
    
    private func handleDetectedPlace(_ place: GMSPlace) {
        let logger = NotificationLogger.shared
        guard let placeId = place.placeID else {
            logger.log(.error, "No place ID available, aborting place detection")
            return
        }
        
        logger.log(.venue, """
            ==========================================
            🏢 Processing Detected Place:
            Name: \(place.name ?? "Unknown")
            ID: \(placeId)
            Types: \(place.types?.joined(separator: ", ") ?? "Unknown")
            ==========================================
            """)
        
        // Increment and log visit count
        frequentlyVisitedVenues[placeId, default: 0] += 1
        let visitCount = frequentlyVisitedVenues[placeId, default: 0]
        logger.log(.venue, "Visit count for this venue: \(visitCount)/\(frequentVisitThreshold) threshold")
        
        // Check if this is a frequently visited venue
        if visitCount >= frequentVisitThreshold {
            logger.log(.notification, "⛔️ Notification blocked: Frequent visitor threshold reached (\(visitCount) visits)")
            return
        }
        
        // Log current notification state
        logger.log(.notification, """
            Current Notification State:
            - Total notifications today: \(notifiedVenues.count)/\(maxDailyNotifications)
            - Notified venues: \(notifiedVenues.keys.joined(separator: ", "))
            """)
        
        // Check if we've already notified about this venue recently
        if let lastNotificationDate = notifiedVenues[placeId] {
            let timeSince = Date().timeIntervalSince(lastNotificationDate)
            let timeRemaining = venueCooldown - timeSince
            logger.log(.notification, """
                ⏰ Venue Cooldown Check:
                - Last notification: \(lastNotificationDate)
                - Time since last: \(Int(timeSince))s
                - Cooldown period: \(Int(venueCooldown))s
                - Time remaining: \(Int(timeRemaining))s
                """)
            
            if timeSince < venueCooldown {
                logger.log(.notification, "⛔️ Notification blocked: Venue still in cooldown period")
                return
            }
        }
        
        // Check if we've reached the daily notification limit
        if notifiedVenues.count >= maxDailyNotifications {
            logger.log(.notification, "⛔️ Notification blocked: Daily limit reached (\(maxDailyNotifications) notifications)")
            return
        }
        
        // Check if enough time has passed since the last notification (any venue)
        if let lastTime = lastNotificationTime {
            let timeSince = Date().timeIntervalSince(lastTime)
            let timeRemaining = notificationCooldown - timeSince
            logger.log(.notification, """
                ⏰ Global Cooldown Check:
                - Last notification: \(lastTime)
                - Time since last: \(Int(timeSince))s
                - Cooldown period: \(Int(notificationCooldown))s
                - Time remaining: \(Int(timeRemaining))s
                """)
            
            if timeSince < notificationCooldown {
                logger.log(.notification, "⛔️ Notification blocked: Global cooldown still active")
                return
            }
        }
        
        // All checks passed, proceed with notification
        logger.log(.notification, """
            ✅ All checks passed for venue:
            - Not a frequent venue (\(visitCount) visits)
            - Not in venue cooldown
            - Not in global cooldown
            - Daily limit not reached (\(notifiedVenues.count)/\(maxDailyNotifications))
            Proceeding with notification...
            """)
        
        // Send the notification
        sendNotification(for: place)
        
        // Persist the updated data
        persistData()
        
        logger.log(.venue, """
            ==========================================
            ✅ Place Processing Complete
            ==========================================
            """)
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
