//
//  RecordAudioViewController.swift
//  Noise
//
//  Created by Jonathan on 12/02/2024.
//

import UIKit
import CoreLocation
import AVFoundation

class RecordAudioViewController: UIViewController {
    
    @IBOutlet weak var recordIcon: UIImageView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var happyWithRecordingButton: UIButton!
    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var warningMicAccess: UILabel!
    
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var audioFilename: URL?
    
    var countdownTimer: Timer?
    var countdownSeconds = 5
    
    var placeName: String?
    var placeAddress: String?
    var placeLon: CLLocationDegrees?
    var placeLat: CLLocationDegrees?
    var placeDistance: String?
    var placeID: String?
    var userLocationLon: CLLocationDegrees?
    var userLocationLat: CLLocationDegrees?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the View
        recordIcon.tintColor = UIColor.blue
        recordButton.isEnabled = true
        playButton.isEnabled = false
        warningMicAccess.isHidden = true
        happyWithRecordingButton.isHidden = true
        countdownLabel.isHidden = true
        
        // Set up Recording
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Permission was granted
                        print("Recording permission granted")
                    } else {
                        // Permission was denied
                        print("Recording permission denied")
                        self.recordButton.isEnabled = false
                        self.recordIcon.tintColor = UIColor.gray
                        self.warningMicAccess.isHidden = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.navigationController?.popToRootViewController(animated: true)
                            // Here you should inform the user and possibly guide them to the Settings app
                        }
                        
                    }
                }
            }
        } catch {
            // An error occurred when setting up the audio session
            print("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    
    @IBAction func recordPressed(_ sender: UIButton) {
        
        // Start recording
        if audioRecorder == nil {
            startRecording()
            print("Recording started...")
            
            // Hide the waveform icon and show the countdownLabel
            recordIcon.isHidden = true
            countdownLabel.isHidden = false
            playButton.isEnabled = false
            
            // Initialize countdown seconds
            countdownSeconds = 5
            countdownLabel.text = String(countdownSeconds)
            
            // Start the countdown timer
            countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
            
            
        } else {
            finishRecording(success: true)
            playButton.isEnabled = true
        }
        
    }
    
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        
        guard let audioFilename = audioFilename else { return }
        playButton.tintColor = UIColor.green
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.play()
        } catch {
            print("Could not load file for playback: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.playButton.tintColor = UIColor.blue
        }
        
    }
    
    
    @IBAction func happyWithRecordingPressing(_ sender: UIButton) {
        
        happyWithRecordingButton.tintColor = UIColor.green
        recordButton.isEnabled = false
        playButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "recordGo3", sender: self)
            self.recordButton.isEnabled = true
            self.playButton.isEnabled = true
            self.happyWithRecordingButton.tintColor = UIColor.blue
        }
        
    }
    
    
    @objc func updateCountdown() {
        countdownSeconds -= 1
        countdownLabel.text = String(countdownSeconds)
        
        if countdownSeconds <= 0 {
            // Stop the timer
            countdownTimer?.invalidate()
            countdownTimer = nil
            
            // Show the waveform icon again
            recordIcon.isHidden = false
            countdownLabel.isHidden = true
        }
    }
    
    
    func startRecording() {
        audioFilename = getDocumentsDirectory().appendingPathComponent("\(placeID!).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            // Update UI to indicate recording
            recordIcon.tintColor = UIColor.red
            recordButton.tintColor = UIColor.red
            happyWithRecordingButton.isEnabled = false
            
            // Schedule to stop the recording after X seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.finishRecording(success: true)
                
            }
            
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Update UI to indicate not recording and has recorded
        recordIcon.tintColor = UIColor.blue
        playButton.isEnabled = true
        happyWithRecordingButton.isHidden = false
        happyWithRecordingButton.isEnabled = true
        recordIcon.isHidden = false
        countdownLabel.isHidden = true
        countdownLabel.isHidden = true
        recordButton.tintColor = UIColor.blue
        
        // Stop the timer if it's still running
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        
        if success {
            print("Recording finished successfully.")
        } else {
            print("Recording failed or was stopped.")
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
            }
        }
    }
}

/*
 
 ---- MARK: Extentions from here on! ----
 
 */

extension RecordAudioViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}


