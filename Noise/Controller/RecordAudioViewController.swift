//
//  RecordAudioViewController.swift
//  Noise
//
//  Created by Jonathan on 12/02/2024.
//

import UIKit
import AVFoundation

class RecordAudioViewController: UIViewController {

    @IBOutlet weak var recordIcon: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var happyWithRecordingButton: UIButton!
    //var audioRecorder: AVAudioRecorder?
    //var recordingSession: AVAudioSession?
    
    var placeName: String?
    var placeAddress: String?
    var placeDistance: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordView.layer.borderWidth = 5
        recordView.layer.borderColor = UIColor.white.cgColor
        playButton.isEnabled = false
        happyWithRecordingButton.isHidden = true
    }
    

    @IBAction func recordPressed(_ sender: UIButton) {
        
        recordIcon.tintColor = UIColor.red
        print("Recording started...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.recordIcon.tintColor = UIColor.blue
            print("Recording ended.")
            self.playButton.isEnabled = true
            self.happyWithRecordingButton.isHidden = false
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
    
    
    /*
    // MARK: - Navigation
     
     
     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
