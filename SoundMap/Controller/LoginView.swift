//
//  LoginView.swift
//  SoundMap
//
//  Created by Jonathan Karl on 25.05.25.
//

// LoginView.swift  (KEEP it tiny)
import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: UserViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Log in or Sign up")
                .font(.title2).bold()

            Button {
                vm.googleSignIn(); dismiss()
            } label: {
                Label("Continue with Google", systemImage: "globe")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }

        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}
