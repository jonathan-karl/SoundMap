//
//  MoreInfoViewController.swift
//  Noise
//
//  Created by Jonathan on 16/02/2024.
//

import UIKit
import CoreLocation
import FirebaseFirestore

class MoreInfoViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var conversationButton: UISegmentedControl!
    @IBOutlet weak var optionsTableView: UITableView!
    
    var placeName: String?
    var placeAddress: String?
    var placeLon: CLLocationDegrees?
    var placeLat: CLLocationDegrees?
    var placeDistance: String?
    var placeID: String?
    var userLocationLon: CLLocationDegrees?
    var userLocationLat: CLLocationDegrees?
    var audioFilename: URL?
    var currentTimestamp: Timestamp?
    var currentNoiseLevel: Float?

    let conversationButtonOptions = ["Comfortable", "Manageable", "Challenging"]
    var conversationDifficulty: String?

    let noiseSourcesOptions = [
        "Crowd chatter",
        "Music",
        "Kitchen noise",
        "Traffic Outside",
        "Air Conditioning",
        "Bar Activities",
        "People Coming In and Out",
        "Children and Pets",
        "Other"
    ]
    var noiseSources: Set<String> = []
    
    var timerForShowScrollIndicator: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.isEnabled = false
        
        optionsTableView.isHidden = false // Not hidden initially
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        optionsTableView.allowsMultipleSelection = true // Enable multiple selection

        optionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Adjust the frame or constraints of optionsTableView based on content size or set a maximum height

    }
    
    @IBAction func conversationButtonChanged(_ sender: UISegmentedControl) {
        conversationDifficulty = conversationButtonOptions[conversationButton.selectedSegmentIndex]
        print((conversationDifficulty ?? "") as String)
        
        switch conversationDifficulty {
        case conversationButtonOptions[0]:
            conversationButton.selectedSegmentTintColor = UIColor(red: 67/255.0, green: 190/255.0, blue: 90/255.0, alpha: 1)
        case conversationButtonOptions[1]:
            conversationButton.selectedSegmentTintColor = UIColor(red: 232/255.0, green: 185/255.0, blue: 5/255.0, alpha: 1)
        case conversationButtonOptions[2]:
            conversationButton.selectedSegmentTintColor = UIColor(red: 236/255.0, green: 55/255.0, blue: 45/255.0, alpha: 1)
        default:
            conversationButton.selectedSegmentTintColor = UIColor.gray
        }
        
        // Set the next Button to say next, now that we have started to fill data.
        nextButton.isEnabled = true
        
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        
        nextButton.tintColor = UIColor.green
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "recordGo4", sender: self)
            self.nextButton.tintColor = UIColor.blue
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(true)
            startTimerForShowScrollIndicator()
        }
        
        @objc func showScrollIndicatorsInContacts() {
            UIView.animate(withDuration: 0.001) {
                self.optionsTableView.flashScrollIndicators()
            }
        }
        
        func startTimerForShowScrollIndicator() {
            self.timerForShowScrollIndicator = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.showScrollIndicatorsInContacts), userInfo: nil, repeats: true)
        }
    
    // MARK: - Navigation

     // Carry over information to the UploadViewController
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "recordGo4" {
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
                 destinationVC.conversationDifficulty = conversationDifficulty
                 destinationVC.noiseSources = noiseSources
                 destinationVC.currentTimestamp = currentTimestamp
                 destinationVC.currentNoiseLevel = currentNoiseLevel
             }
         }
     }
}


extension MoreInfoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noiseSourcesOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = noiseSourcesOptions[indexPath.row]

        // Prevent the cell from turning grey upon selection
        cell.selectionStyle = .none

        // Configure the checkmark for selected and deselected states
        if noiseSources.contains(noiseSourcesOptions[indexPath.row]) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark // Set the checkmark when selected
            noiseSources.insert(noiseSourcesOptions[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none // Remove the checkmark when deselected
            noiseSources.remove(noiseSourcesOptions[indexPath.row])
        }
    }

}
