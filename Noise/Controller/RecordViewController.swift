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

class RecordViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func recordNewEntryGoPressed(_ sender: UIButton) {
        
        // Optionally, perform any checks or preparations here
        self.performSegue(withIdentifier: "recordGo", sender: self)
    }
    
}

