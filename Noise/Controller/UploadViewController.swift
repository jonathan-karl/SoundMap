//
//  UploadViewController.swift
//  Noise
//
//  Created by Jonathan on 13/02/2024.
//

import UIKit
import CoreLocation

class UploadViewController: UIViewController {

    var placeName: String?
    var placeAddress: String?
    var placeDistance: String?
    var placeID: String?
    var userLocation: CLLocation?
    var recording: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func uploadPressed(_ sender: UIButton) {
        
        print(placeName!)
        print(userLocation!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Returning to Root View Controller")
            self.navigationController?.popToRootViewController(animated: true)
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
