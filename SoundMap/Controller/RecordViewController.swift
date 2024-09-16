//
//  RecordViewController.swift
//  Noise
//
//  Created by Jonathan on 11/02/2024.
//
import UIKit
import AVFoundation
import GooglePlaces
import GoogleMaps
import CoreLocation
import GoogleAnalytics

class RecordViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var recordNewEntryGoButton: UIButton!
    @IBOutlet weak var promptTextLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var warningAccessLabel: UILabel!
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("RecordViewController viewDidLoad called")
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Check recording permission
        checkRecordingPermission()
        
        // Initially disable the button until we know the authorization status
        recordNewEntryGoButton?.isEnabled = false
        
        // Hide the warning label
        warningAccessLabel?.isHidden = true
    }
    
    @IBAction func recordNewEntryGoPressed(_ sender: UIButton) {
        print("Record New Entry button pressed")        
        // Track button press event
        if let tracker = GAI.sharedInstance().defaultTracker {
            print("Attempting to send event: Category - User Action, Action - Tap, Label - Record New Entry")
            tracker.send(GAIDictionaryBuilder.createEvent(
                withCategory: "User Action",
                action: "Tap",
                label: "Record New Entry",
                value: nil
            ).build() as [NSObject : AnyObject])
        } else {
            print("Failed to get default tracker")
        }
        
        self.performSegue(withIdentifier: "recordGo", sender: self)
    }
    
    func checkRecordingPermission() {
        print("Checking recording permission")
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            print("Recording permission granted")
            checkLocationPermission()
        case .denied:
            print("Recording permission denied")
            updateUIForDeniedPermissions()
        case .undetermined:
            print("Recording permission undetermined")
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Recording permission granted after request")
                        self?.checkLocationPermission()
                    } else {
                        print("Recording permission denied after request")
                        self?.updateUIForDeniedPermissions()
                    }
                }
            }
        @unknown default:
            print("Unknown recording permission status")
            updateUIForDeniedPermissions()
        }
    }
    
    func checkLocationPermission() {
        print("Checking location permission")
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted")
            promptTextLabel?.textColor = UIColor.black
            titleLabel?.textColor = UIColor.black
            recordNewEntryGoButton?.isEnabled = true
            warningAccessLabel?.isHidden = true
        case .notDetermined:
            print("Location permission not determined")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location permission denied or restricted")
            updateUIForDeniedPermissions()
        @unknown default:
            print("Unknown location permission status")
            break
        }
    }
    
    func updateUIForDeniedPermissions() {
        print("Updating UI for denied permissions")
        recordNewEntryGoButton?.isEnabled = false
        warningAccessLabel?.isHidden = false
        promptTextLabel?.textColor = UIColor.lightGray
        titleLabel?.textColor = UIColor.lightGray
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationPermission()
    }
}

