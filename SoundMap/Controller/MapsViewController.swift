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


class MapsViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    var locationManager: CLLocationManager?
    var clusterManager: GMUClusterManager!
    var visibleLabels: [GMSMarker: Bool] = [:]
    var markers: [GMSMarker] = []
    
    // Temporary storage for details to pass to DetailedViewController
    var conversationDifficultyElements: Set<String> = []
    var conversationDifficultyFrequencies: Set<Int> = []
    var noiseSourcesElements: Set<String> = []
    var noiseSourcesFrequencies: Set<Int> = []
    var placeAddress: String?
    var placeName: String?
    var placeType: String?
    var mapView: GMSMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Manage the location
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        
        
        
        // Set the initial camera position
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 2.0)
        
        // Create the map with the custom map ID and camera
        let mapID = GMSMapID(identifier: "9e950bcba4f24a30")
        self.mapView = GMSMapView(frame: view.bounds, mapID: mapID, camera: camera)
        view.addSubview(self.mapView as UIView)
        
        // Set the delegate
        self.mapView.delegate = self
        
        // Configure the map style to hide default POIs and labels
        do {
            if let styleURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json") {
                self.mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                print("Unable to find MapStyle.json")
            }
        } catch {
            print("One or more of the map styles failed to load. \(error)")
        }
        
        // Initialize cluster manager
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        
        // Fetch and display markers
        fetchAndDisplayMarkers()
        
        // Register self to listen to GMSMapViewDelegate events
        clusterManager.setMapDelegate(self)
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
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        mapView.selectedMarker = marker
        // center the map on tapped marker
        mapView.animate(toLocation: marker.position)
        
        // check if a cluster icon was tapped
        if marker.userData is GMUCluster {
            // zoom in on tapped cluster
            mapView.animate(toZoom: mapView.camera.zoom + 1)
            NSLog("Did tap cluster")
            return true
        } else {
            if let _ = marker.userData as? MarkerData {
                // Perform the segue and pass marker.userData as sender
                self.performSegue(withIdentifier: "seeDetails", sender: marker.userData)
            }
            NSLog("Did tap a normal marker")
            return false // or true based on your handling
        }
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        infoWindow.backgroundColor = UIColor.white
        infoWindow.layer.cornerRadius = 10
        infoWindow.layer.shadowColor = UIColor.black.cgColor
        infoWindow.layer.shadowOffset = CGSize(width: 0, height: 2)
        infoWindow.layer.shadowOpacity = 0.2
        infoWindow.layer.shadowRadius = 4
        
        let nameLabel = UILabel(frame: CGRect(x: 10, y: 10, width: 230, height: 40))
        nameLabel.text = marker.title
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.numberOfLines = 0
        infoWindow.addSubview(nameLabel)
        
        let addressLabel = UILabel(frame: CGRect(x: 10, y: 60, width: 230, height: 30))
        addressLabel.text = marker.snippet
        addressLabel.font = UIFont.systemFont(ofSize: 12)
        addressLabel.textColor = .gray
        addressLabel.numberOfLines = 0
        infoWindow.addSubview(addressLabel)
        
        return infoWindow
    }
    
    
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        updateVisibleLabels()
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
                // Assuming markerData has a property 'placeType' which stores the type as a String
                let markerType = markerData.placeType // Adjust this if your MarkerData class stores type differently
                marker.icon = createCustomMarkerImage(with: marker.title ?? "", isVisible: visibleLabels[marker] ?? false, type: markerType)
            } else {
                // Handle case where there is no valid markerData, use a default type if necessary
                marker.icon = createCustomMarkerImage(with: marker.title ?? "", isVisible: visibleLabels[marker] ?? false, type: "default")
            }
        }
    }

    
    func createCustomMarkerImage(with name: String, isVisible: Bool, type: String) -> UIImage {
        let markerView = createCustomMarkerView(with: name, isVisible: isVisible, type: type)
        UIGraphicsBeginImageContextWithOptions(markerView.bounds.size, false, 0)
        markerView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    
    func createCustomMarkerView(with name: String, isVisible: Bool, type: String) -> UIView {
        let markerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        
        // Icon
        let iconView = UIImageView(frame: CGRect(x: 90, y: 20, width: 20, height: 20))
        
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
        
        iconView.tintColor = .black
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
            label.sizeToFit()
            label.frame.size.width += 20 // Add some padding
            label.center = CGPoint(x: markerView.bounds.width / 2, y: 10)
            markerView.addSubview(label)
        }
        
        return markerView
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
    
    func fetchAndDisplayMarkers() {
        clusterManager.clearItems() // Clear existing items before adding new ones
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
            
            var uniqueIds = Set<String>() // To keep track of unique IDs
            
            for document in documents {
                let data = document.data()
                
                guard let id = data["placeID"] as? String else {
                    print("ID not found for document: \(document.documentID)")
                    continue
                }
                
                if uniqueIds.contains(id) {
                    continue
                }
                
                uniqueIds.insert(id)
                
                if let latitude = data["placeLat"] as? Double,
                   let longitude = data["placeLon"] as? Double,
                   let placeName = data["placeName"] as? String,
                   let placeAddress = data["placeAddress"] as? String {
                    
                    // Provide a default value of "" for placeType if it's missing
                    let placeType = data["placeType"] as? String ?? ""
                    
                    let markerData = MarkerData(
                        placeName: placeName,
                        placeAddress: placeAddress,
                        placeType: placeType,
                        conversationDifficultyElements: data["conversationDifficultyElements"] as? [String] ?? [],
                        conversationDifficultyFrequencies: data["conversationDifficultyFrequencies"] as? [Int] ?? [],
                        noiseSourcesElements: data["noiseSourcesElements"] as? [String] ?? [],
                        noiseSourcesFrequencies: data["noiseSourcesFrequencies"] as? [Int] ?? []
                    )
                    
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    marker.title = placeName
                    marker.snippet = placeAddress
                    marker.userData = markerData
                    marker.icon = createCustomMarkerImage(with: placeName, isVisible: true, type: placeType)
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                    self.clusterManager.add(marker)
                    self.markers.append(marker)
                    
                } else {
                    print("Document \(document.documentID) does not contain valid location data.")
                    print("Missing fields: \(data)")
                }
            }
            
            // Ensure cluster() is called on the main thread
            DispatchQueue.main.async {
                self.clusterManager.cluster()
                self.updateVisibleLabels()
            }
        }
    }

    
    // Carry over information
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "seeDetails",
           let destinationVC = segue.destination as? DetailedViewController,
           let markerData = sender as? MarkerData { // Cast sender to MarkerData
            // Pass data to destinationVC
            destinationVC.placeName = markerData.placeName
            destinationVC.placeAddress = markerData.placeAddress
            destinationVC.conversationDifficultyElements = markerData.conversationDifficultyElements
            destinationVC.conversationDifficultyFrequencies = markerData.conversationDifficultyFrequencies
            destinationVC.noiseSourcesElements = markerData.noiseSourcesElements
            destinationVC.noiseSourcesFrequencies = markerData.noiseSourcesFrequencies
        }
    }
    
    
}


class MarkerData {
    var placeName: String
    var placeAddress: String
    var placeType: String // Add placeType as a property
    var conversationDifficultyElements: [String]
    var conversationDifficultyFrequencies: [Int]
    var noiseSourcesElements: [String]
    var noiseSourcesFrequencies: [Int]
    
    // Update the initializer to include placeType
    init(placeName: String, placeAddress: String, placeType: String, conversationDifficultyElements: [String], conversationDifficultyFrequencies: [Int], noiseSourcesElements: [String], noiseSourcesFrequencies: [Int]) {
        self.placeName = placeName
        self.placeAddress = placeAddress
        self.placeType = placeType
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
