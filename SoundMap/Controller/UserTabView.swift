import SwiftUI
import UserNotifications
import CoreLocation
import GoogleAnalytics

class UserViewModel: ObservableObject {
    @Published var notificationStatus: String = "Checking..."
    @Published var locationStatus: String = "Checking..."
    @Published var appVersion = "1.2"
    
    private let locationManager = CLLocationManager()
    
    init() {
        checkNotificationStatus()
        checkLocationStatus()
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.notificationStatus = "Enabled"
                case .denied:
                    self.notificationStatus = "Disabled"
                case .notDetermined:
                    self.notificationStatus = "Not Determined"
                @unknown default:
                    self.notificationStatus = "Unknown"
                }
                
                // Track notification status
                if let tracker = GAI.sharedInstance().defaultTracker {
                    tracker.send(GAIDictionaryBuilder.createEvent(
                        withCategory: "User Status",
                        action: "Notification Status",
                        label: self.notificationStatus,
                        value: nil
                    ).build() as [NSObject : AnyObject])
                }
                
            }
        }
    }
    
    func checkLocationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            locationStatus = "Always"
        case .authorizedWhenInUse:
            locationStatus = "When in Use"
        case .denied, .restricted:
            locationStatus = "Disabled"
        case .notDetermined:
            locationStatus = "Not Determined"
        @unknown default:
            locationStatus = "Unknown"
        }
        
        // Track location status
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.send(GAIDictionaryBuilder.createEvent(
                withCategory: "User Status",
                action: "Location Status",
                label: locationStatus,
                value: nil
            ).build() as [NSObject : AnyObject])
        }
        
    }
}

struct UserTabView: View {
    @StateObject private var viewModel = UserViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    welcomeSection
                    helpAndPreferencesSection
                    ignoredLocationsSection
                    feedbackSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to SoundMap")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Map and explore noise levels in cafés, restaurants, and bars to find your perfect spot.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var helpAndPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help Us Improve")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(helpText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Notifications:")
                    Spacer()
                    Text(viewModel.notificationStatus)
                        .foregroundColor(statusColor(for: viewModel.notificationStatus))
                        .fontWeight(viewModel.notificationStatus == "Enabled" ? .bold : .regular)
                }
                
                HStack {
                    Text("Location Access:")
                    Spacer()
                    Text(viewModel.locationStatus)
                        .foregroundColor(statusColor(for: viewModel.locationStatus))
                        .fontWeight(viewModel.locationStatus == "Always" ? .bold : .regular)
                }
            }
            
            VStack(spacing: 8) {
                Button("Open SoundMap Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text("Note: Relaunch the app to see updated status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var ignoredLocationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ignored Locations")
                .font(.headline)
                .foregroundColor(.primary)
            
            NavigationLink(destination: IgnoredLocationsView()) {
                HStack {
                    Text("Manage Ignored Locations")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statusColor(for status: String) -> Color {
        let greenColor = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor(red: 0, green: 0.8, blue: 0, alpha: 1) :  // Darker green for dark mode
            UIColor(red: 0, green: 0.6, blue: 0, alpha: 1)    // Lighter green for light mode
        })
        
        switch status {
        case "Enabled", "Always":
            return greenColor
        default:
            return .secondary
        }
    }
    
    private var helpText: AttributedString {
        var text = AttributedString("Enabling 'Always Allow Location Access' and notifications helps us build a more comprehensive database of noise levels, providing better recommendations for you and other users. We'll send you a notification when you're in a restaurant, cafe, or bar to request a noise recording. You can make SoundMap better for everyone.")
        
        if let range = text.range(of: "Always Allow Location Access") {
            text[range].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        if let range = text.range(of: "notifications") {
            text[range].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        
        return text
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feedback")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: sendFeedbackEmail) {
                HStack {
                    Text("Send us a brief note")
                    Spacer()
                    Image(systemName: "envelope")
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func sendFeedbackEmail() {
        let email = "jonathan.karl2501@gmail.com"
        let subject = "SoundMap Feedback - [Insert Topic here]"
        let body = "Feel free to keep it brief and sweet. We always work to make SoundMap better and your feedback is a big part of that."
        
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

struct UserTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserTabView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            UserTabView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
