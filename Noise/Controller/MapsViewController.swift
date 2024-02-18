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
        }
        
        NSLog("Did tap a normal marker")
        return false
    }
    
    func fetchAndDisplayMarkers() {
        let db = Firestore.firestore()
        db.collection("uploads").getDocuments { [weak self] (querySnapshot, err) in
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
                   let title = data["placeName"] as? String {
                    
                    // Since the ID is unique, create the marker
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    marker.title = title
                    marker.snippet = "Conversation Difficulty: Comfortable (24), Manageable (21), Challenging (3)\n\nNoises detected: Kids (7), Music (89)"
                    
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
    
    func colorForConversationDifficulty(_ difficulty: String) -> UIColor {
        switch difficulty {
        case "Comfortable":
            return UIColor.green // Example color for "Comfortable"
        case "Manageable":
            return UIColor.orange // Example color for "Manageable"
        case "Challenging":
            return UIColor.red // Example color for "Challenging"
        default:
            return UIColor.gray // Default color if difficulty is unknown
        }
    }
}

