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
import CoreData
import GoogleAnalytics
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var locationManager: LocationNotificationManager?
    var tracker: GAITracker?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyAXUmF5lT8ItlZ9AGK5qyV6Pvy4tOONfw4")
        GMSPlacesClient.provideAPIKey("AIzaSyAXUmF5lT8ItlZ9AGK5qyV6Pvy4tOONfw4")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Analytics
        let gai = GAI.sharedInstance()
        gai?.tracker(withTrackingId: "G-WGM7F7BER0")
        // Optional: configure GAI options
        gai?.trackUncaughtExceptions = true  // Report uncaught exceptions
        gai?.logger.logLevel = .verbose  // Remove before app release
        
        // Force light mode for the entire app
        setAppearanceForAllScenes()
        
        // Configure LocationNotificationManager
        locationManager = LocationNotificationManager.shared
        locationManager?.configure()
        locationManager?.startMonitoring()
        
        // Check notification permission status
        LocationNotificationManager.shared.checkNotificationPermissions()
        
        // Request notification authorization
        requestNotificationAuthorization()
        
        
        // If the app was launched due to a significant location change
        if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] as? NSNumber,
           locationKey.boolValue {
            print("App launched due to significant location change")
            // The locationManager will check authorization before actually monitoring
            locationManager?.startMonitoring()
        }
        
        UNUserNotificationCenter.current().delegate = self
        
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        // Here you would typically send this token to your server
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        locationManager?.stopMonitoring()
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
        }
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
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the received notification
        let userInfo = response.notification.request.content.userInfo
        if let placeId = userInfo["placeId"] as? String {
            print("Notification tapped for place: \(placeId)")
            // Here you can add logic to open the relevant part of your app
        }
        completionHandler()
    }
    
}
