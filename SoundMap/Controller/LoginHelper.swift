//
//  LoginHelper.swift
//  SoundMap
//
//  Created by Jonathan Karl on 25.05.25.
//

//  LoginHelper.swift  (new file, keeps LoginView tiny)
import FirebaseAuth
import GoogleSignIn
import Firebase

enum LoginHelper {
    /// Launches the Google sheet and signs the user in (or up).
    static func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let rootVC   = (UIApplication.shared.connectedScenes.first as?
                              UIWindowScene)?.windows.first?.rootViewController
        else { return }
        
        GIDSignIn.sharedInstance.configuration = .init(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { res, err in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            
            // 1️⃣ Unwrap the *optional* pieces
            guard
                let user    = res?.user,
                let idToken = user.idToken?.tokenString
            else { return }
            
            // 2️⃣ The access-token string is *not* optional
            let accessToken = user.accessToken.tokenString
            
            // 3️⃣ Create the Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { _, e in
                if let e = e { print(e.localizedDescription) }
            }
        }
        
    }
}

