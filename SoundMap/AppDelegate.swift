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
import Firebase
import FirebaseAuth
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var locationManager: LocationNotificationManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyAXUmF5lT8ItlZ9AGK5qyV6Pvy4tOONfw4")
        GMSPlacesClient.provideAPIKey("AIzaSyAXUmF5lT8ItlZ9AGK5qyV6Pvy4tOONfw4")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Force light mode for the entire app
        setAppearanceForAllScenes()
        
        // Configure LocationNotificationManager
        let locationManager = LocationNotificationManager.shared
        locationManager.configure()
        locationManager.requestLocationPermissions()
        locationManager.startMonitoring()
        
        
        
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
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Handle background events if needed
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
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
    
    // Helper method to set appearance for all scenes
    private func setAppearanceForAllScenes() {
        if #available(iOS 15.0, *) {
            // Use the new scene-based approach for iOS 15 and later
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.overrideUserInterfaceStyle = .light
                    }
                }
            }
        } else if #available(iOS 13.0, *) {
            // Use the window-based approach for iOS 13 and 14
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        } else {
            // For iOS 12 and earlier, set the status bar style
            UIApplication.shared.statusBarStyle = .default
        }
    }
    
    
}
