//
//  UploadViewController.swift
//  Noise
//
//  Created by Jonathan on 13/02/2024.
//

import UIKit
import CoreLocation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

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
    var userLocationLon: CLLocationDegrees?
    var userLocationLat: CLLocationDegrees?
    var audioFilename: URL?
    var conversationDifficulty: String?
    var noiseSources: Set<String> = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uploadProgressView.progress = 0.0 // Initialize with 0 progress
        uploadProgressView.isHidden = true
        thankYouLabel.isHidden = true
    }
    

    @IBAction func uploadPressed(_ sender: UIButton) {
        
        // Some print statements to verify data is carried over from the download
        print(placeName!)
        print(placeAddress!)
        print(placeID!)
        print(placeLon!)
        print(placeLat!)
        print(placeDistance!)
        
        print(userLocationLon!)
        print(userLocationLat!)
        print(audioFilename!)
        print(conversationDifficulty!)
        print(noiseSources)
        
        uploadProgressView.isHidden = false
        uploadAudioFile()

        
    }

    func uploadAudioFile() {
        guard let audioURL = audioFilename else {
            print("Audio filename is nil")
            return
        }

        let storageRef = Storage.storage().reference().child("recordings/\(audioURL.lastPathComponent)")
        print(storageRef)
        let uploadTask = storageRef.putFile(from: audioURL, metadata: nil)
        print(uploadTask)

        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            print(percentComplete)
            
            DispatchQueue.main.async {
                self.uploadProgressView.progress = percentComplete
            }
        }
        
        uploadTask.observe(.success) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            storageRef.downloadURL { url, error in
                if let downloadURL = url {
                    strongSelf.uploadMetadata(audioURL: downloadURL.absoluteString)
                } else {
                    print("Error retrieving download URL: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
            DispatchQueue.main.async {
                strongSelf.animateUIChanges()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("Returning to Root View Controller")
                self?.navigationController?.popToRootViewController(animated: true)
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
    }
    
    func uploadMetadata(audioURL: String) {
        // Assume we're using Firestore
        let db = Firestore.firestore()
        let currentTimestamp = Timestamp(date: Date())
        
        // Convert Set to Array
        let noiseSourcesArray = Array(noiseSources)
        
        let metadata: [String: Any] = [
            "placeName": placeName ?? "",
            "placeAddress": placeAddress ?? "",
            "placeLon": placeLon ?? 0,
            "placeLat": placeLat ?? 0,
            "placeDistance": placeDistance ?? "",
            "placeID": placeID ?? "",
            "userLocationLat": userLocationLat ?? 0,
            "userLocationLon": userLocationLon ?? 0,
            "uploadTime": currentTimestamp,
            "conversationDifficulty": conversationDifficulty ?? "",
            "noiseSources": noiseSourcesArray
            ]
        
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        ref = db.collection("uploads/").addDocument(data: metadata) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
                // Here you can handle the successful upload and navigate the user
                self.navigateAfterUpload()
            }
        }
    }

    func navigateAfterUpload() {
        DispatchQueue.main.async {
            print("Returning to Root View Controller")
            self.navigationController?.popToRootViewController(animated: true)
        }
    }


    
    
}
