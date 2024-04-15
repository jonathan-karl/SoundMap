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
    
    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager: CLLocationManager?
    var clusterManager: GMUClusterManager!
    
    // Temporary storage for details to pass to DetailedViewController
    var conversationDifficultyElements: Set<String> = []
    var conversationDifficultyFrequencies: Set<Int> = []
    var noiseSourcesElements: Set<String> = []
    var noiseSourcesFrequencies: Set<Int> = []
    var placeAddress: String?
    var placeName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Manage the location`
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        
        // Manage the map
        mapView.delegate = self
        // Set the initial camera position
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 2.0)
        let mapID = GMSMapID(identifier: "9e950bcba4f24a30")
        mapView.camera = camera
        
        
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        
        // Add the markers to the cluster manager instead of the map directly
        fetchAndDisplayMarkers()
        
        // Register self to listen to GMSMapViewDelegate events
        clusterManager.setMapDelegate(self)
        
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

    
    func fetchAndDisplayMarkers() {
        clusterManager.clearItems() // Clear existing items before adding new ones
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
                    //print("Duplicate placeID found: \(id), skipping")
                    continue
                }
                
                // Now that we've confirmed the id is unique, add it to the set
                uniqueIds.insert(id)
            
                if let latitude = data["placeLat"] as? Double,
                   let longitude = data["placeLon"] as? Double,
                   let placeName = data["placeName"] as? String,
                   let placeAddress = data["placeAddress"] as? String,
                   let WIP = data["WIP"] as? String,
                   let conversationDifficultyElementsArray = data["conversationDifficultyElements"] as? [String],
                   let conversationDifficultyFrequenciesArray = data["conversationDifficultyFrequencies"] as? [Int],
                   let noiseSourcesElementsArray = data["noiseSourcesElements"] as? [String],
                   let noiseSourcesFrequenciesArray = data["noiseSourcesFrequencies"] as? [Int] {
                    
                    let markerData = MarkerData(
                        placeName: placeName,
                        placeAddress: placeAddress,
                        conversationDifficultyElements: conversationDifficultyElementsArray,
                        conversationDifficultyFrequencies: conversationDifficultyFrequenciesArray,
                        noiseSourcesElements: noiseSourcesElementsArray,
                        noiseSourcesFrequencies: noiseSourcesFrequenciesArray
                    )
                    
                    // Since the ID is unique, create the marker
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    marker.title = placeName
                    marker.snippet = WIP
                    marker.userData = markerData
                    // Add the marker to the cluster manager
                    self.clusterManager.add(marker)
                } else {
                    print("Document \(document.documentID) does not contain valid location data.")
                }
                
                
                
                
            }
            
            // Ensure cluster() is called on the main thread
            DispatchQueue.main.async {
                self.clusterManager.cluster()
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
    var conversationDifficultyElements: [String]
    var conversationDifficultyFrequencies: [Int]
    var noiseSourcesElements: [String]
    var noiseSourcesFrequencies: [Int]

    init(placeName: String, placeAddress: String, conversationDifficultyElements: [String], conversationDifficultyFrequencies: [Int], noiseSourcesElements: [String], noiseSourcesFrequencies: [Int]) {
        self.placeName = placeName
        self.placeAddress = placeAddress
        self.conversationDifficultyElements = conversationDifficultyElements
        self.conversationDifficultyFrequencies = conversationDifficultyFrequencies
        self.noiseSourcesElements = noiseSourcesElements
        self.noiseSourcesFrequencies = noiseSourcesFrequencies
    }
}
