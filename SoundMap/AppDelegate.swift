//
//  AppDelegate.swift
//  Noise
//
//  Created by Jonathan on 11/02/2024.
//

import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseCore
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyAXUmF5lT8ItlZ9AGK5qyV6Pvy4tOONfw4")
        GMSPlacesClient.provideAPIKey("AIzaSyAXUmF5lT8ItlZ9AGK5qyV6Pvy4tOONfw4")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = userActivity.webpageURL,
           let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true) {
            
            // Check if the URL is for a specific venue
            if let venueID = components.queryItems?.first(where: { $0.name == "venueID" })?.value {
                // Try to open the venue in the app
                if openVenueInApp(venueID: venueID) {
                    return true
                }
            }
            
            // If we couldn't handle the URL, open the App Store
            if let appStoreURL = URL(string: "https://apps.apple.com/app/soundmap/id6482854844") {
                application.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
        return false
    }
    
    private func openVenueInApp(venueID: String) -> Bool {
        // Implement this method to open the specific venue in your app
        // Return true if successful, false otherwise
        return false
    }
    
    
}

