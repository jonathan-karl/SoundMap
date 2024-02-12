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


class MapsViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager: CLLocationManager?
    var clusterManager: GMUClusterManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        
        // Manage the location`
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        
        // Manage the map
        mapView.delegate = self
        // Set the initial camera position
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 3.0)
        mapView.camera = camera
        
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        
        // Add the markers to the cluster manager instead of the map directly
        addMarkersToCluster()
        print("Markers added.")
        
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
    
    
    func addMarkersToCluster() {
        guard let path = Bundle.main.path(forResource: "Health Facilities in Kenya - HPV Vaccine- VCF - HPV Vaccine Facility Recommendation Data", ofType: "csv") else { return }
        let url = URL(fileURLWithPath: path)
        
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let rows = data.components(separatedBy: "\n")
            
            for row in rows.dropFirst() {
                let columns = row.components(separatedBy: ",")
                if columns.count > 2, let latitude = Double(columns[4]), let longitude = Double(columns[3]) {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    marker.title = columns[2]
                    marker.snippet = columns[1]
                    clusterManager.add(marker)
                    //print("Marker added.")
                }
            }
        } catch {
            print("Error reading CSV file")
        }
    }
    
    
    
}

