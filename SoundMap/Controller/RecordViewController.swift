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

class RecordViewController: UIViewController, CLLocationManagerDelegate
{
    
    @IBOutlet weak var recordNewEntryGoButton: UIButton!
    @IBOutlet weak var promptTextLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var warningAccessLabel: UILabel!
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Request location authorization
        
        // Check recording permission
        checkRecordingPermission()
        
        // Initially disable the button until we know the authorization status
        recordNewEntryGoButton.isEnabled = false
        
        // Hide the warning label
        warningAccessLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check recording permission each time the view appears
        checkRecordingPermission()
        
        // No need to call checkLocationPermission() here directly, as it's already called
        // at the end of checkRecordingPermission() if the recording permission is granted.
        // If recording permission is not granted, the UI will be updated accordingly
        // in the checkRecordingPermission() method.
    }
    
    
    @IBAction func recordNewEntryGoPressed(_ sender: UIButton) {
        // Optionally, perform any checks or preparations here
        self.performSegue(withIdentifier: "recordGo", sender: self)
    }
    
    func checkRecordingPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            // Recording permission is granted, proceed to check location permission
            checkLocationPermission()
        case .denied:
            // Recording permission is denied, update UI accordingly
            updateUIForDeniedPermissions()
        case .undetermined:
            // Request recording permission
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Permission granted, proceed to check location permission
                        self.checkLocationPermission()
                    } else {
                        // Permission denied, update UI accordingly
                        self.updateUIForDeniedPermissions()
                    }
                }
            }
        @unknown default:
            // Handle unexpected case
            updateUIForDeniedPermissions()
        }
    }
    
    func checkLocationPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Location services are authorized, request location
            // Location permission is granted, enable the button
            promptTextLabel.textColor = UIColor.black
            titleLabel.textColor = UIColor.black
            recordNewEntryGoButton.isEnabled = true
            warningAccessLabel.isHidden = true
        case .notDetermined:
            // Request for authorization
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Location permission is not granted, update UI accordingly
            updateUIForDeniedPermissions()
            break
        default:
            break
        }
    }
    
    func updateUIForDeniedPermissions() {
        // Disable the button and show the warning label
        recordNewEntryGoButton.isEnabled = false
        warningAccessLabel.isHidden = false
        promptTextLabel.textColor = UIColor.lightGray
        titleLabel.textColor = UIColor.lightGray
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationPermission()
    }
}

