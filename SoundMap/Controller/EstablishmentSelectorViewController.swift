//
//  EstablishmentSelectorViewController.swift
//  Noise
//
//  Created by Jonathan on 12/02/2024.
//

import UIKit
import GooglePlaces
import GoogleMaps
import CoreLocation

class EstablishmentSelectorViewController: UIViewController,  UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var placeConfirmationButton: UIButton!
    @IBOutlet weak var placeSelectorView: UIView!
    
    var placesClient: GMSPlacesClient!
    var searchResults: [GMSAutocompletePrediction] = []
    var locationManager: CLLocationManager!
    var currentUserLocation: CLLocation?
    
    var selectedPlaceName: String?
    var selectedPlaceAddress: String?
    var selectedPlaceDistance: String?
    var selectedPlaceLon: CLLocationDegrees?
    var selectedPlaceLat: CLLocationDegrees?
    var selectedPlaceID: String?
    var userLocationLon: CLLocationDegrees?
    var userLocationLat: CLLocationDegrees?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        placesClient = GMSPlacesClient.shared()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        // Register the UITableViewCell class with the table view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        detailsLabel.isHidden = true
        placeConfirmationButton.isHidden = true
        
    }
    
    @IBAction func placeConfirmationButtonPressed(_ sender: UIButton) {
        
        placeConfirmationButton.tintColor = UIColor.green
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "recordGo2", sender: self)
            self.placeConfirmationButton.tintColor = UIColor.blue
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty, let userLocation = currentUserLocation else {
            searchResults = []
            tableView.reloadData()
            return
        }
        let filter = GMSAutocompleteFilter()
        filter.types = ["restaurant", "cafe", "night_club", "bar", "lodging"]
        // ADD RESTRICTION ON LOCATION BOUNDS. SHOULD BE IN A RADIUS TO THE LOCATION OF less than 200m
        let northEast = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude + 0.002, longitude: userLocation.coordinate.longitude + 0.002)
        let southWest = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude - 0.002, longitude: userLocation.coordinate.longitude - 0.002)
        filter.locationRestriction = GMSPlaceRectangularLocationOption(northEast, southWest)
        
        print("Searching for: \(searchText)")
        
        placesClient.findAutocompletePredictions(fromQuery: searchText,
                                                 filter: filter,
                                                 sessionToken: nil) { (results, error) in
            if let error = error {
                print("Autocomplete error: \(error.localizedDescription)")
                return
            }
            guard let results = results else {
                print("No results found.")
                return
            }
            //print("Found \(results.count) results.")
            self.searchResults = results
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        detailsLabel.isHidden = true // Hide the label
        placeConfirmationButton.isHidden = true
        placeConfirmationButton.tintColor = UIColor.blue
        tableView.isHidden = false // Show the table view
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Assuming "Cell" is the identifier for a cell in your search results table view.
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure the cell with data from the searchResults array.
        let prediction = searchResults[indexPath.row]
        cell.textLabel?.text = prediction.attributedPrimaryText.string
        cell.detailTextLabel?.text = prediction.attributedSecondaryText?.string
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.resignFirstResponder() // Dismiss the keyboard
        
        if let cell = tableView.cellForRow(at: indexPath) {
            // Change cell background color to blue when selected
            cell.backgroundColor = UIColor.blue
            // Optional: Change text color to improve readability against the blue background
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.textColor = UIColor.white
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Change cell background color to blue when selected
                cell.backgroundColor = UIColor.white
                // Optional: Change text color to improve readability against the blue background
                cell.textLabel?.textColor = UIColor.black
                cell.detailTextLabel?.textColor = UIColor.black
            }
        }
        
        if indexPath.row < searchResults.count {
            let prediction = searchResults[indexPath.row]
            // Set the search bar text to the selected row's title
            searchBar.text = prediction.attributedPrimaryText.string
            
            guard let currentUserLocation = self.currentUserLocation else {
                print("User location is not available.")
                // Optionally, show an alert or a loading indicator
                return
            }
            
            fetchPlaceDetails(for: prediction.placeID, userLocation: currentUserLocation)
        } else {
            print("Selected index is out of range")
        }
        
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("Running didUpdateLocations Function")
        if let location = locations.last {
            currentUserLocation = location
            userLocationLat = currentUserLocation?.coordinate.latitude
            userLocationLon = currentUserLocation?.coordinate.longitude
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Location services are authorized, request location
            locationManager?.requestLocation()
            print("Location Requested.")
        case .notDetermined:
            // Request for authorization
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Location services are not allowed
            break
        default:
            break
        }
    }
    
    func fetchPlaceDetails(for placeID: String, userLocation: CLLocation) {
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: [.name, .formattedAddress, .placeID, .coordinate], sessionToken: nil) { (place, error) in
            guard let place = place, error == nil else {
                print("Fetch place error: \(error?.localizedDescription ?? "")")
                return
            }
            
            DispatchQueue.main.async {
                let placeLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                let distance = userLocation.distance(from: placeLocation) / 1000 // Convert meters to kilometers
                let distanceString = String(format: "%.1f", distance)
                
                // Store the details temporarily
                self.selectedPlaceName = place.name ?? "No Name"
                self.selectedPlaceAddress = place.formattedAddress ?? "No address"
                self.selectedPlaceLon = place.coordinate.longitude
                self.selectedPlaceLat = place.coordinate.latitude
                self.selectedPlaceDistance = "\(distanceString)km"
                self.selectedPlaceID = place.placeID
                
                // Create the attributed string for the details
                self.detailsLabel.attributedText = self.attributedDetailString(
                    name: place.name ?? "No Name",
                    address: place.formattedAddress ?? "No address",
                    distance: distanceString
                )
                
                self.tableView.isHidden = true // Hide the table view
                self.detailsLabel.isHidden = false // Make the label visible
                self.placeConfirmationButton.isHidden = false
            }
        }
    }
    
    func attributedDetailString(name: String, address: String, distance: String) -> NSAttributedString {
        let boldAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]
        let regularAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .thin)]
        
        let attributedString = NSMutableAttributedString(string: "Name: ", attributes: boldAttributes)
        attributedString.append(NSAttributedString(string: "\(name)\n", attributes: regularAttributes))
        attributedString.append(NSAttributedString(string: "Address: ", attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: "\(address)\n", attributes: regularAttributes))
        attributedString.append(NSAttributedString(string: "Distance from you: ", attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: "\(distance)km\n", attributes: regularAttributes))
        
        return attributedString
    }
    
    
    //MARK: - Navigation
    
    // Carry over information
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "recordGo2" {
            if let destinationVC = segue.destination as? RecordAudioViewController {
                // Pass data to destinationVC
                destinationVC.placeName = selectedPlaceName
                destinationVC.placeAddress = selectedPlaceAddress
                destinationVC.placeLon = selectedPlaceLon
                destinationVC.placeLat = selectedPlaceLat
                destinationVC.placeDistance = selectedPlaceDistance
                destinationVC.placeID = selectedPlaceID
                destinationVC.userLocationLon = userLocationLon
                destinationVC.userLocationLat = userLocationLat
            }
        }
    }
    
}
