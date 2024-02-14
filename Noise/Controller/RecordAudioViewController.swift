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
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var happyWithRecordingButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var audioFilename: URL?
    
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
        
        // Set up View Look
        recordView.layer.borderWidth = 5
        recordView.layer.borderColor = UIColor.white.cgColor
        playButton.isEnabled = false
        happyWithRecordingButton.isHidden = true
        
        // Set up Recording
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                // Permission was granted
                                print("Recording permission granted")
                            } else {
                                // Permission was denied
                                print("Recording permission denied")
                                // Here you should inform the user and possibly guide them to the Settings app
                            }
                        }
                    }
        } catch {
            // An error occurred when setting up the audio session
            print("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    

    @IBAction func recordPressed(_ sender: UIButton) {
        
        if audioRecorder == nil {
                startRecording()
                print("Recording started...")
            } else {
                finishRecording(success: true)
            }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        
        guard let audioFilename = audioFilename else { return }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
                audioPlayer?.play()
            } catch {
                print("Could not load file for playback: \(error.localizedDescription)")
            }
    }
    
    
    @IBAction func happyWithRecordingPressing(_ sender: UIButton) {
        
        happyWithRecordingButton.tintColor = UIColor.green
        recordView.layer.borderColor = UIColor.green.cgColor
        recordButton.isEnabled = false
        playButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "recordGo3", sender: self)
        }
    }
    
    
    func startRecording() {
        audioFilename = getDocumentsDirectory().appendingPathComponent("\(placeID).m4a")
        
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
            
            // Schedule to stop the recording after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.finishRecording(success: true)
                
            }
            
        } catch {
            finishRecording(success: false)
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        // Update UI to indicate not recording and has recorded
        recordIcon.tintColor = UIColor.blue
        self.playButton.isEnabled = true
        self.happyWithRecordingButton.isHidden = false
        
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
             if let destinationVC = segue.destination as? UploadViewController {
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
