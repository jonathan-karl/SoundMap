//
//  UploadViewController.swift
//  Noise
//
//  Created by Jonathan on 13/02/2024.
//

import UIKit
import CoreLocation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleAnalytics


class UploadViewController: UIViewController {
    
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    
    var placeName: String?
    var placeAddress: String?
    var placeLon: CLLocationDegrees?
    var placeLat: CLLocationDegrees?
    var placeDistance: String?
    var placeID: String?
    var placeType: String?
    var userLocationLon: CLLocationDegrees?
    var userLocationLat: CLLocationDegrees?
    var audioFilename: URL?
    var conversationDifficulty: String?
    var noiseSources: Set<String> = []
    var currentTimestamp: Timestamp?
    var currentNoiseLevel: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uploadProgressView.isHidden = true
        thankYouLabel.isHidden = true
    }
    
    
    @IBAction func uploadPressed(_ sender: UIButton) {
        
        // Track button press event
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.send(GAIDictionaryBuilder.createEvent(
                withCategory: "User Action",
                action: "Tap",
                label: "Upload",
                value: nil
            ).build() as [NSObject : AnyObject])
        }
        
        uploadProgressView.isHidden = false
        uploadMetadata()
        
    }
    
    func uploadMetadata() {
        print("Trying to upload Metadata.")
        
        // Show and initialize the progress view
        uploadProgressView.isHidden = false
        uploadProgressView.progress = 0.0
        
        let db = Firestore.firestore()
        let noiseSourcesArray = Array(noiseSources)
        
        let metadata: [String: Any] = [
            "placeName": placeName ?? "",
            "placeAddress": placeAddress ?? "",
            "placeLon": placeLon ?? 0,
            "placeLat": placeLat ?? 0,
            "placeDistance": placeDistance ?? "",
            "placeID": placeID ?? "",
            "placeType": placeType ?? "",
            "userLocationLat": userLocationLat ?? 0,
            "userLocationLon": userLocationLon ?? 0,
            "uploadTime": currentTimestamp ?? Timestamp(date: Date()),
            "currentNoiseLevel": currentNoiseLevel ?? 0,
            "conversationDifficulty": conversationDifficulty ?? "",
            "noiseSources": noiseSourcesArray
        ]
        
        // Define a flag to control the progress view's completion
        var uploadCompleted = false
        
        // Start uploading metadata to Firestore
        db.collection("uploads").addDocument(data: metadata) { [weak self] err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Metadata successfully uploaded")
                uploadCompleted = true
                
                // Increment user submission count in Firestore
                if let user = Auth.auth().currentUser {
                    let db = Firestore.firestore()
                    let nickname = UserDefaults.standard.string(forKey: "nickname") ?? ""
                    
                    db.collection("users").document(user.uid).setData([
                        "nickname": nickname,
                        "submissionCount": FieldValue.increment(Int64(1))
                    ], merge: true)
                }
                
                DispatchQueue.main.async {
                    self?.uploadProgressView.progress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.animateUIChanges()
                    }
                }
                
            }
        }
        
        // Simulate progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let weakSelf = self else { return }
            
            // Adjust this value as needed to stop the progress just before 100%
            let maxProgressBeforeCompletion: Float = 0.95
            
            if weakSelf.uploadProgressView.progress >= maxProgressBeforeCompletion && !uploadCompleted {
                // If the progress reaches the cap and the upload hasn't completed, stop the timer.
                timer.invalidate()
            } else if weakSelf.uploadProgressView.progress < maxProgressBeforeCompletion {
                // Safely increment the progress without completing it
                weakSelf.uploadProgressView.progress += 0.05
            }
        }
    }
    
    func animateUIChanges() {
        UIView.animate(withDuration: 0.5, animations: {
            self.uploadButton.alpha = 0
            self.uploadProgressView.alpha = 0
        }) { _ in
            self.uploadButton.isHidden = true
            self.uploadProgressView.isHidden = true
            
            self.thankYouLabel.isHidden = false
            self.thankYouLabel.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self.thankYouLabel.alpha = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Returning to Root View Controller")
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    
    
}
