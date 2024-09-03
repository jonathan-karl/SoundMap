//
//  ViewController.swift
//  Noise
//
//  Created by Jonathan on 11/02/2024.
//

import UIKit
import CoreLocation
import GoogleMaps
import GoogleMapsUtils
import FirebaseFirestore
import SafariServices

class MapsViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, GMUClusterManagerDelegate {
    
    private var customRenderer: CustomClusterRenderer!
    private var isZoomingToCluster = false
    private var customInfoWindow: CustomInfoWindow?
    private var selectedMarker: GMSMarker?
    var locationManager: CLLocationManager?
    var clusterManager: GMUClusterManager!
    var visibleLabels: [GMSMarker: Bool] = [:]
    var markers: [GMSMarker] = []
    var mapView: GMSMapView!
    
    var onTap: (() -> Void)?
    
    // Temporary storage for details to pass to DetailedViewController
    var conversationDifficultyElements: Set<String> = []
    var conversationDifficultyFrequencies: Set<Int> = []
    var noiseSourcesElements: Set<String> = []
    var noiseSourcesFrequencies: Set<Int> = []
    var placeAddress: String?
    var placeName: String?
    var placeType: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Setting up MapsViewController")
        setupLocationManager()
        setupMapView()
        setupClusterManager()
        
        // Fetch and display markers
        fetchAndDisplayMarkers()
        
        // Ensure tab bar is visible
        self.tabBarController?.tabBar.isHidden = false
        
        // Check if the tab bar is covered by the map view
        if let tabBarFrame = self.tabBarController?.tabBar.frame,
           let mapViewFrame = self.mapView?.frame {
            print("Tab Bar Frame: \(tabBarFrame)")
            print("Map View Frame: \(mapViewFrame)")
        }
        
        // Set up tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func setupMapView() {
        // Set the initial camera position
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 2.0)
        
        // Create the map with the custom map ID and camera
        let mapID = GMSMapID(identifier: "9e950bcba4f24a30")
        mapView = GMSMapView(frame: view.bounds, mapID: mapID, camera: camera)
        view.addSubview(mapView)
        
        // Set the delegate
        mapView.delegate = self
        
        // Configure the map style to hide default POIs and labels
        do {
            if let styleURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                print("Unable to find MapStyle.json")
            }
        } catch {
            print("Failed to load map style. Error: \(error)")
        }
    }
    
    private func setupClusterManager() {
        print("Setting up ClusterManager")
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager.setDelegate(self, mapDelegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateVisibleLabels()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Current Location Authorization Status: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location Authorization Granted.")
            locationManager?.requestLocation()
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        case .notDetermined:
            print("Location Authorization Not Determined, requesting.")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location Authorization Denied or Restricted.")
        default:
            break
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager?.stopUpdatingLocation() // Stop location updates if you only need it once
        fetchAndDisplayMarkers()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        print("Cluster tapped: \(cluster.count) items")
        let newCamera = GMSCameraPosition.camera(
            withTarget: cluster.position,
            zoom: mapView.camera.zoom + 1
        )
        let update = GMSCameraUpdate.setCamera(newCamera)
        mapView.animate(with: update)
        return true
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        // Handle individual cluster item taps if needed
        if let markerData = (clusterItem as? GMSMarker)?.userData as? MarkerData {
            // Do something with markerData
            print("Tapped on marker: \(markerData.placeName)")
        }
        return true
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        
        if let tappedMarker = findMarker(at: point) {
            showCustomInfoWindow(for: tappedMarker)
        } else {
            hideCustomInfoWindow()
        }
    }
    
    func findMarker(at point: CGPoint) -> GMSMarker? {
        for marker in self.markers {
            let markerPoint = mapView.projection.point(for: marker.position)
            let frame = CGRect(x: markerPoint.x - 20, y: markerPoint.y - 20, width: 40, height: 40)
            if frame.contains(point) {
                return marker
            }
        }
        return nil
    }
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let _ = marker.userData as? GMUCluster {
            // Let the cluster manager handle cluster taps
            return false
        } else if let markerData = marker.userData as? MarkerData {
            // Handle regular marker taps
            if marker == selectedMarker {
                hideCustomInfoWindow()
            } else {
                showCustomInfoWindow(for: marker)
            }
            return true
        }
        return false
    }
    
    func zoomToCluster(_ cluster: GMUCluster) {
        isZoomingToCluster = true
        var bounds = GMSCoordinateBounds(coordinate: cluster.position, coordinate: cluster.position)
        for item in cluster.items {
            bounds = bounds.includingCoordinate(item.position)
        }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 100)
        mapView.animate(with: update)
        
        // Reset the flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isZoomingToCluster = false
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        hideCustomInfoWindow()
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        clusterManager.cluster()
        updateVisibleLabels()
        if let marker = selectedMarker {
            updateInfoWindowPosition(for: marker)
        }
    }
    
    private func showCustomInfoWindow(for marker: GMSMarker) {
        hideCustomInfoWindow()
        
        guard let markerData = marker.userData as? MarkerData else {
            print("Invalid marker data")
            return
        }
        
        let infoWindow = CustomInfoWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 320))
        
        // Calculate the most common conversation difficulty
        let conversationDifficulties = ["Comfortable": 1, "Manageable": 2, "Challenging": 3]
        let totalScore = zip(markerData.conversationDifficultyElements, markerData.conversationDifficultyFrequencies)
            .reduce(0) { $0 + (conversationDifficulties[$1.0] ?? 0) * $1.1 }
        let totalFrequency = markerData.conversationDifficultyFrequencies.reduce(0, +)
        let averageScore = Double(totalScore) / Double(totalFrequency)
        let mostCommonDifficulty: String
        switch averageScore {
        case ..<1.5:
            mostCommonDifficulty = "Comfortable"
        case 1.5..<2.5:
            mostCommonDifficulty = "Manageable"
        default:
            mostCommonDifficulty = "Challenging"
        }
        
        // Calculate the top 3 noise sources with frequencies
        let topNoises = zip(markerData.noiseSourcesElements, markerData.noiseSourcesFrequencies)
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { ($0.0, Int(Double($0.1) / Double(markerData.noiseSourcesFrequencies.reduce(0, +)) * 100)) }
        
        let venueData = VenueNoiseData(
            venueName: markerData.placeName,
            noiseLevel: Int(markerData.averageNoiseLevel),
            conversationEase: mostCommonDifficulty,
            topNoises: topNoises
        )
        infoWindow.configure(with: venueData)
        infoWindow.onTap = { [weak self] in
            self?.performSegue(withIdentifier: "seeDetails", sender: markerData)
        }
        
        infoWindow.onGoogleMapsTap = { [weak self] in
            self?.openInGoogleMaps(placeName: markerData.placeName, latitude: marker.position.latitude, longitude: marker.position.longitude)
        }
        
        infoWindow.onShareTap = { [weak self] in
            self?.shareVenueInfo(venueData: venueData)
        }
        
        mapView.addSubview(infoWindow)
        customInfoWindow = infoWindow
        selectedMarker = marker
        
        updateInfoWindowPosition(for: marker)
    }
    
    private func updateInfoWindowPosition(for marker: GMSMarker) {
        guard let infoWindow = customInfoWindow else { return }
        
        let markerPoint = mapView.projection.point(for: marker.position)
        let markerFrame = CGRect(x: markerPoint.x - 20, y: markerPoint.y - 40, width: 40, height: 40)
        
        // Calculate the info window position
        let infoWindowX = markerFrame.midX - infoWindow.frame.width / 2
        let infoWindowY = markerFrame.minY - infoWindow.frame.height - 25 // Reduced gap between pin and info window
        
        // Ensure the info window stays within the map bounds
        let maxX = mapView.frame.width - infoWindow.frame.width
        let minX: CGFloat = 0
        let x = max(minX, min(infoWindowX, maxX))
        
        infoWindow.frame = CGRect(x: x, y: infoWindowY, width: infoWindow.frame.width, height: infoWindow.frame.height)
    }
    
    private func hideCustomInfoWindow() {
        customInfoWindow?.removeFromSuperview()
        customInfoWindow = nil
        selectedMarker = nil
    }
    
    private func openInGoogleMaps(placeName: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let encodedName = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(latitude),\(longitude)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func shareVenueInfo(venueData: VenueNoiseData) {
        let shareText = """
            Check out the noise levels at \(venueData.venueName)!
            Noise Level: \(venueData.noiseLevel) dB
            Conversation Ease: \(venueData.conversationEase)
            Top Noises: \(venueData.topNoises.map { "\($0.0) (\($0.1)%)" }.joined(separator: ", "))
            
            Download SoundMap to explore more: https://apps.apple.com/app/soundmap/id6482854844
            """
        
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        guard let markerData = marker.userData as? MarkerData else {
            return nil
        }
        
        let customInfoWindow = CustomInfoWindow(frame: CGRect(x: 0, y: 0, width: 250, height: 200))
        let venueData = VenueNoiseData(
            venueName: markerData.placeName,
            noiseLevel: Int(markerData.averageNoiseLevel),
            conversationEase: markerData.conversationDifficultyElements.first ?? "Unknown",
            topNoises: zip(markerData.noiseSourcesElements, markerData.noiseSourcesFrequencies)
                .map { ($0, $1) }
                .prefix(3)
                .map { ($0, Int($1)) }
        )
        customInfoWindow.configure(with: venueData)
        
        // Set up the tap handler for the info window
        customInfoWindow.onTap = { [weak self] in
            self?.performSegue(withIdentifier: "seeDetails", sender: markerData)
        }
        
        return customInfoWindow
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let markerData = marker.userData as? MarkerData {
            self.performSegue(withIdentifier: "seeDetails", sender: markerData)
        }
    }
    
    func updateVisibleLabels() {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        
        var occupiedRects: [CGRect] = []
        
        for marker in markers {
            let point = mapView.projection.point(for: marker.position)
            let labelRect = CGRect(x: point.x - 100, y: point.y - 40, width: 200, height: 20)
            
            if bounds.contains(marker.position) {
                if !occupiedRects.contains(where: { $0.intersects(labelRect) }) {
                    visibleLabels[marker] = true
                    occupiedRects.append(labelRect)
                } else {
                    visibleLabels[marker] = false
                }
            } else {
                visibleLabels[marker] = false
            }
        }
        
        for marker in markers {
            if let markerData = marker.userData as? MarkerData {
                marker.icon = createCustomMarkerImage(
                    with: marker.title ?? "",
                    isVisible: visibleLabels[marker] ?? false,
                    type: markerData.placeType,
                    averageNoiseLevel: markerData.averageNoiseLevel
                )
            }
        }
    }
    
    
    func createCustomMarkerImage(with name: String, isVisible: Bool, type: String, averageNoiseLevel: Double) -> UIImage {
        let markerView = createCustomMarkerView(with: name, isVisible: isVisible, type: type, averageNoiseLevel: averageNoiseLevel)
        UIGraphicsBeginImageContextWithOptions(markerView.bounds.size, false, 0)
        markerView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    func createCustomMarkerView(with name: String, isVisible: Bool, type: String, averageNoiseLevel: Double) -> UIView {
        let markerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 70)) // Reduced height slightly
        
        // Icon
        let iconView = UIImageView(frame: CGRect(x: 88, y: 46, width: 24, height: 24)) // Adjusted position
        
        // Set the icon based on the type
        switch type {
        case "restaurant":
            iconView.image = UIImage(systemName: "fork.knife")
        case "bar":
            iconView.image = UIImage(systemName: "mug.fill")
        case "cafe":
            iconView.image = UIImage(systemName: "cup.and.saucer.fill")
        case "lodging":
            iconView.image = UIImage(systemName: "bed.double.fill")
        default:
            iconView.image = UIImage(systemName: "mappin.circle.fill") // Default icon
        }
        
        // Set the tint color based on the average noise level
        iconView.tintColor = getColorForNoiseLevel(averageNoiseLevel)
        // Increase the weight of the icon for better visibility
        if let config = iconView.image?.withConfiguration(UIImage.SymbolConfiguration(weight: .bold)) {
            iconView.image = config
        }
        markerView.addSubview(iconView)
        
        // Text
        if isVisible {
            let label = PaddingLabel()
            label.text = name
            label.textAlignment = .center
            label.backgroundColor = .white
            label.layer.cornerRadius = 10
            label.layer.masksToBounds = true
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.numberOfLines = 2 // Allow up to 2 lines
            label.lineBreakMode = .byTruncatingTail // Truncate with ... if it exceeds 2 lines
            
            // Calculate the size of the label based on its content
            let maxSize = CGSize(width: 180, height: 36) // Max width and slightly reduced max height
            let size = label.sizeThatFits(maxSize)
            
            // Set the frame of the label
            label.frame = CGRect(x: 0, y: 0, width: size.width + 20, height: min(size.height + 10, 36))
            label.center = CGPoint(x: markerView.bounds.width / 2, y: 23) // Adjusted y-position
            
            markerView.addSubview(label)
        }
        
        return markerView
    }
    
    
    func getColorForNoiseLevel(_ db: Double) -> UIColor {
        switch db {
        case ..<70:
            return UIColor(red: 2/255, green: 226/255, blue: 97/255, alpha: 1) // Green
        case 70..<76:
            return UIColor(red: 255/255, green: 212/255, blue: 0, alpha: 1) // Yellow
        case 76..<80:
            return UIColor(red: 213/255, green: 94/255, blue: 23/255, alpha: 1) // Orange
        default:
            return UIColor(red: 209/255, green: 33/255, blue: 19/255, alpha: 1) // Red
        }
    }
    
    func createCustomMarkerIcon(with name: String) -> UIImage {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        label.text = name
        label.textAlignment = .center
        label.backgroundColor = .white
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.font = UIFont.boldSystemFont(ofSize: 12)
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let tabBarHeight = self.tabBarController?.tabBar.frame.height {
            let mapFrame = CGRect(x: 0,
                                  y: 0,
                                  width: view.bounds.width,
                                  height: view.bounds.height - tabBarHeight)
            mapView.frame = mapFrame
        }
    }
    
    // Update fetchAndDisplayMarkers() to use clusterManager.add() instead of creating GMSMarker directly
    func fetchAndDisplayMarkers() {
        clusterManager.clearItems()
        markers.removeAll()
        
        let db = Firestore.firestore()
        db.collection("outputs").getDocuments { [weak self] (querySnapshot, err) in
            guard let self = self else { return }
            
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents or querySnapshot is nil")
                return
            }
            
            var uniqueIds = Set<String>()
            
            for document in documents {
                let data = document.data()
                
                guard let id = data["placeID"] as? String,
                      let latitude = data["placeLat"] as? Double,
                      let longitude = data["placeLon"] as? Double,
                      let placeName = data["placeName"] as? String,
                      let placeAddress = data["placeAddress"] as? String,
                      let averageNoiseLevel = data["averageNoiseLevel"] as? Double else {
                    continue
                }
                
                if uniqueIds.contains(id) { continue }
                uniqueIds.insert(id)
                
                let placeType = data["placeType"] as? String ?? ""
                
                let markerData = MarkerData(
                    placeName: placeName,
                    placeAddress: placeAddress,
                    placeType: placeType,
                    averageNoiseLevel: averageNoiseLevel,
                    conversationDifficultyElements: data["conversationDifficultyElements"] as? [String] ?? [],
                    conversationDifficultyFrequencies: data["conversationDifficultyFrequencies"] as? [Int] ?? [],
                    noiseSourcesElements: data["noiseSourcesElements"] as? [String] ?? [],
                    noiseSourcesFrequencies: data["noiseSourcesFrequencies"] as? [Int] ?? []
                )
                
                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                marker.title = placeName
                marker.snippet = placeAddress
                marker.userData = markerData
                marker.icon = self.createCustomMarkerImage(
                    with: placeName,
                    isVisible: true,
                    type: placeType,
                    averageNoiseLevel: averageNoiseLevel
                )
                marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                self.clusterManager.add(marker)
                self.markers.append(marker)
            }
            
            DispatchQueue.main.async {
                self.clusterManager.cluster()
                self.updateVisibleLabels()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seeDetails",
           let destinationVC = segue.destination as? DetailedViewController,
           let markerData = sender as? MarkerData {
            destinationVC.placeName = markerData.placeName
            destinationVC.placeAddress = markerData.placeAddress
            destinationVC.conversationDifficultyElements = markerData.conversationDifficultyElements
            destinationVC.conversationDifficultyFrequencies = markerData.conversationDifficultyFrequencies
            destinationVC.noiseSourcesElements = markerData.noiseSourcesElements
            destinationVC.noiseSourcesFrequencies = markerData.noiseSourcesFrequencies
        }
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension MapsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allow the gesture if the touch is not on the info window
        if let customInfoWindow = self.customInfoWindow {
            let location = touch.location(in: mapView)
            if customInfoWindow.frame.contains(location) {
                return false
            }
        }
        return true
    }
}


class MarkerData {
    var placeName: String
    var placeAddress: String
    var placeType: String
    var averageNoiseLevel: Double
    var conversationDifficultyElements: [String]
    var conversationDifficultyFrequencies: [Int]
    var noiseSourcesElements: [String]
    var noiseSourcesFrequencies: [Int]
    
    init(placeName: String, placeAddress: String, placeType: String, averageNoiseLevel: Double, conversationDifficultyElements: [String], conversationDifficultyFrequencies: [Int], noiseSourcesElements: [String], noiseSourcesFrequencies: [Int]) {
        self.placeName = placeName
        self.placeAddress = placeAddress
        self.placeType = placeType
        self.averageNoiseLevel = averageNoiseLevel
        self.conversationDifficultyElements = conversationDifficultyElements
        self.conversationDifficultyFrequencies = conversationDifficultyFrequencies
        self.noiseSourcesElements = noiseSourcesElements
        self.noiseSourcesFrequencies = noiseSourcesFrequencies
    }
}


class PaddingLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
}
