//
//  RecordAudioViewController.swift
//  Noise
//
//  Created by Jonathan on 12/02/2024.
//

import UIKit
import CoreLocation
import AVFoundation
import FirebaseFirestore


class RecordAudioViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var decibelLabel: UILabel!
    @IBOutlet weak var recordDBButton: UIButton!
    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var warningMicAccess: UILabel!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFilename: URL?
    var isMonitoring = false // Track whether we are currently monitoring
    var updateTimer: Timer? // Timer for updating the decibel levels
    
    var placeName: String?
    var placeAddress: String?
    var placeLon: CLLocationDegrees?
    var placeLat: CLLocationDegrees?
    var placeDistance: String?
    var placeID: String?
    var userLocationLon: CLLocationDegrees?
    var userLocationLat: CLLocationDegrees?
    var currentTimestamp = Timestamp(date: Date())
    var decibelLevels: [Float] = [] // Stores recent decibel levels
    var currentNoiseLevel: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the View
        warningMicAccess.isHidden = true
        
        // Set up the recording session immediately
        setupRecordingSession()
    }
    
    
    @IBAction func recordDBPressed(_ sender: UIButton) {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
        isMonitoring = !isMonitoring // Toggle the monitoring state
        
        recordDBButton.tintColor = UIColor.green
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "recordGo3", sender: self)
            self.recordDBButton.tintColor = UIColor.blue
        }
    }
    
    
    func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [unowned self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startMonitoring() // Start monitoring immediately if permission is granted
                    } else {
                        // Permission was denied
                        self.warningMicAccess.isHidden = false
                    }
                }
            }
        } catch {
            print("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    func startMonitoring() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("temp.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            decibelLabel.isHidden = false // Always show the decibel level
            startDecibelLevelUpdates()
        } catch {
            print("Monitoring failed to start")
        }
    }
    
    func stopMonitoring() {
        audioRecorder?.stop()
        audioRecorder = nil
        updateTimer?.invalidate() // Invalidate the timer to stop updating the decibel levels
        updateTimer = nil // Set the timer to nil
    }
    
    func startDecibelLevelUpdates() {
        updateTimer?.invalidate() // Ensure any existing timer is stopped before creating a new one
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let strongSelf = self, let recorder = strongSelf.audioRecorder else {
                timer.invalidate()
                return
            }
            recorder.updateMeters()
            let decibelLevel = recorder.averagePower(forChannel: 0)
        
            // Convert to decibel
            let db = decibelLevel + 110 // Adjusted formula to convert to dB value
            
            // Add the new decibel level to the array, and remove the oldest if necessary
            if strongSelf.decibelLevels.count >= 30 {
                strongSelf.decibelLevels.removeFirst() // Remove the oldest sample
            }
            strongSelf.decibelLevels.append(db)
            
            // Calculate the moving average
            let sum = strongSelf.decibelLevels.reduce(0, +)
            let movingAverage = sum / Float(strongSelf.decibelLevels.count)
            
            strongSelf.currentNoiseLevel = movingAverage // Assign the moving average to currentNoiseLevel
            print(movingAverage)
            
            DispatchQueue.main.async {
                strongSelf.decibelLabel.text = String(format: "%.0fdB", db)
                // Adjust the color based on the decibel level
                if db < 70 {
                    strongSelf.decibelLabel.textColor = UIColor(red: 2/255, green: 226/255, blue: 97/255, alpha: 1) // Green
                } else if db >= 70 && db <= 76 {
                    strongSelf.decibelLabel.textColor = UIColor(red: 255/255, green: 212/255, blue: 0, alpha: 1) // Yellow
                } else if db > 76 && db <= 80 {
                    strongSelf.decibelLabel.textColor = UIColor(red: 213/255, green: 94/255, blue: 23/255, alpha: 1) // Orange
                } else if db > 81 {
                    strongSelf.decibelLabel.textColor = UIColor(red: 209/255, green: 33/255, blue: 19/255, alpha: 1) // Red
                }
            }
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // Carry over information to the UploadViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "recordGo3" {
            if let destinationVC = segue.destination as? MoreInfoViewController {
                // Pass data to destinationVC
                destinationVC.placeName = placeName
                destinationVC.placeAddress = placeAddress
                destinationVC.placeLat = placeLat
                destinationVC.placeLon = placeLon
                destinationVC.placeDistance = placeDistance
                destinationVC.placeID = placeID
                destinationVC.userLocationLat = userLocationLat
                destinationVC.userLocationLon = userLocationLon
                destinationVC.audioFilename = audioFilename
                destinationVC.currentTimestamp = currentTimestamp
                destinationVC.currentNoiseLevel = currentNoiseLevel
            }
        }
    }
}

/*
 
 ---- MARK: Extentions from here on! ----
 
 */
