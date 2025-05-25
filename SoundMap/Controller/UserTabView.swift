import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import UserNotifications
import CoreLocation
import GoogleAnalytics

final class UserViewModel: ObservableObject {
    @Published var notificationStatus: String = "Checking..."
    @Published var locationStatus: String = "Checking..."
    @Published var appVersion = "1.3"
    
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var searchText: String = ""
    @Published var submissionCount: Int = 0
    @Published var userEmail: String = ""
    @Published var profileImage: UIImage? = nil
    @Published var nicknameError: String?
    @Published var firebaseUser: User?           // nil = logged-out
    @Published var nickname     : String = UserDefaults.standard.string(forKey: "nickname") ?? ""
    var isLoggedIn: Bool { firebaseUser != nil }
    
    var canSeeLeaderboard: Bool {
        firebaseUser != nil &&
        submissionCount > 0 &&
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var filteredLeaderboard: [LeaderboardEntry] {
        guard !searchText.isEmpty else { return leaderboardEntries }
        return leaderboardEntries.filter {
            $0.nickname.lowercased().contains(searchText.lowercased())
        }
    }
    
    private let locationManager = CLLocationManager()
    
    init() {
        checkNotificationStatus()
        checkLocationStatus()
        observeAuthChanges()
        
    }
    
    private func observeAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user        // triggers a UI refresh
            if user == nil {
                // … sign-out branch …
                self?.userEmail = ""
                self?.submissionCount = 0
            } else {
                self?.userEmail = user!.email ?? ""       // NEW — comes from FirebaseAuth
                
                Firestore.firestore().collection("users")
                    .document(user!.uid)
                    .getDocument { snap, _ in
                        guard let data = snap?.data() else { return }
                        self?.nickname        = data["nickname"]        as? String ?? ""
                        self?.userEmail       = data["email"]           as? String ?? self?.userEmail ?? "" // keep Auth value if field missing
                        self?.submissionCount = data["submissionCount"] as? Int    ?? 0
                        
                        // Show leaderboard automatically when the user qualifies
                        if self?.canSeeLeaderboard == true { self?.fetchLeaderboard() }
                    }
                // 🔄 keep local cache in sync with the canonical cloud copy
                UserDefaults.standard.set(self?.nickname,        forKey: "nickname")
                
                // ──  Download Google profile photo ──────────────────────────
                if  let url  = user?.photoURL {                     // ← already set by Firebase
                    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                        guard let data = data,
                              let img  = UIImage(data: data) else { return }
                        DispatchQueue.main.async { self?.profileImage = img }  // published
                    }.resume()
                }

                
            }
        }
    }
    
    // Exposed entry points -------------- //
    func googleSignIn()  { LoginHelper.googleSignIn() }
    func signOut() throws {
        try Auth.auth().signOut()

        // 🔄 purge local cache
        UserDefaults.standard.removeObject(forKey: "nickname")

        // 🔄 reset in-memory values so the UI clears instantly
        nickname        = ""
    }
    
    func saveProfile() {
        guard let user = firebaseUser else { return }
        let cleanName = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let db = Firestore.firestore()
        // 1️⃣  Does somebody else already own this nickname?
        db.collection("users")
          .whereField("nickname", isEqualTo: cleanName)
          .getDocuments { [weak self] snap, error in
              if let error = error {
                  print("🔥 nickname lookup failed:", error.localizedDescription)
                  return
              }

              // Any document whose ID ≠ my UID = duplicate
              if snap?.documents.contains(where: { $0.documentID != user.uid }) == true {
                  print("🚫 nickname taken")
                  self?.nicknameError = "Nickname already taken"   // ← set error
                  return                              // 👉 early-out – don’t save
              }

              // 2️⃣  Safe to save
              // — local cache for offline resilience —
              UserDefaults.standard.set(cleanName,             forKey: "nickname")

              // — remote canonical copy —
              db.collection("users")
                .document(user.uid)
                .setData([
                    "nickname":        cleanName,
                    "email":           user.email ?? ""
                ], merge: true) { err in
                    if let err = err {
                        print("🔥 profile save failed:", err.localizedDescription)
                    } else {
                        self?.nicknameError = nil   
                        print("✅ profile saved")
                    }
                }
          }
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
        let status: String
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            status = "Always"
        case .authorizedWhenInUse:
            status = "When in Use"
        case .denied, .restricted:
            status = "Disabled"
        case .notDetermined:
            status = "Not Determined"
        @unknown default:
            status = "Unknown"
        }
        
        DispatchQueue.main.async {
            self.locationStatus = status
        }
        
        // Track location status
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.send(GAIDictionaryBuilder.createEvent(
                withCategory: "User Status",
                action: "Location Status",
                label: status,
                value: nil
            ).build() as [NSObject : AnyObject])
        }
    }
    
    func fetchLeaderboard() {
        Firestore.firestore()
            .collection("users")
            .order(by: "submissionCount", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self.leaderboardEntries = documents.compactMap { doc in
                        let data = doc.data()
                        return LeaderboardEntry(
                            nickname: data["nickname"] as? String ?? "Anonymous",
                            count: data["submissionCount"] as? Int ?? 0
                        )
                    }
                }
            }
    }
    
    
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let nickname: String
    let count: Int
}

struct UserTabView: View {
    @StateObject private var viewModel = UserViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    welcomeSection
                    if viewModel.canSeeLeaderboard { leaderboardSection }
                    AccountSection(viewModel: viewModel)
                    helpAndPreferencesSection
                    ignoredLocationsSection
                    feedbackSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
            
            .onAppear {
                if viewModel.canSeeLeaderboard { viewModel.fetchLeaderboard() }
            }
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
    
    // MARK: Leaderboard UI
    @ViewBuilder
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leaderboard")
                .font(.headline)
            Text("Who has submitted the most SoundReviews?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Search field (iOS 15+)
            TextField("Search nickname", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)

            // Row list – scrollable only when needed
            Group {
                if viewModel.filteredLeaderboard.count > 10 {
                    ScrollView {
                        rows
                    }
                    .frame(maxHeight: 300)               // ≈10 rows
                } else {
                    rows
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // Re-usable row builder
    @ViewBuilder
    private var rows: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.filteredLeaderboard.indices, id: \.self) { idx in
                let entry = viewModel.filteredLeaderboard[idx]
                HStack {
                    Text("#\(idx + 1)")
                        .fontWeight(.bold)
                        .frame(minWidth: 32, alignment: .leading)

                    Text(entry.nickname)
                        .fontWeight(entry.nickname == viewModel.nickname ? .bold : .regular)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    Text("\(entry.count)")
                        .fontWeight(.bold)
                }
                .padding(.vertical, 4)
            }
        }
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
            
            Text("Ignored locations are places where you don't want to receive noise recording prompts. Use this feature for your home, office, or any regular spots where you prefer not to be notified.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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
        
        let redColor = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1) :  // Brighter red for dark mode
            UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)      // Darker red for light mode
        })
        
        switch status {
        case "Enabled", "Always":
            return greenColor
        default:
            return redColor
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
