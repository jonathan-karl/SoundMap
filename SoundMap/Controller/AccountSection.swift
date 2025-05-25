//
//  AccountSection.swift
//  SoundMap
//
//  Created by Jonathan Karl on 25.05.25.
//

import SwiftUI

struct AccountSection: View {
    @ObservedObject var viewModel: UserViewModel
    @State private var nicknameDirty = false
    
    private func saveNickname() {
        guard !viewModel.nickname.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        viewModel.saveProfile()
        nicknameDirty = false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // ── Signed-out state ──────────────────────────────────────────────
            if viewModel.firebaseUser == nil {
                NavigationLink(destination: LoginView(vm: viewModel)) {
                    HStack {
                        Text("Login or Manage Account")
                        Spacer()
                        Image(systemName: "person.crop.circle")
                    }
                }
                .foregroundColor(.blue)
                
                Text("If you log in you can appear on the leaderboard for submitting SoundReviews.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // ── Signed-in state ───────────────────────────────────────────────
            else {
                HStack(spacing: 12) {
                    if let img = viewModel.profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.userEmail)
                            .font(.subheadline)
                        Button("Sign out", role: .destructive) {
                            try? viewModel.signOut()
                        }
                        .font(.caption)
                    }
                }
                
                HStack(spacing: 6) {
                    Text("Nickname")
                    
                    TextField("Obi-Wan Kenobi", text: $viewModel.nickname)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit {
                            saveNickname()                                // helper below
                        }
                        .onChange(of: viewModel.nickname) { _ in
                            nicknameDirty = true                         // any keystroke → dirty
                        }
                    
                    Button {
                        saveNickname()
                    } label: {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .imageScale(.large)
                            .foregroundColor(nicknameDirty ? .blue : .gray)
                            .opacity(viewModel.nickname.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    }
                    .disabled(!nicknameDirty || viewModel.nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .disabled(viewModel.nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                if let error = viewModel.nicknameError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if viewModel.canSeeLeaderboard == false {
                    Text("You’ll be shown on the leaderboard once you’ve submitted a Nickname & SoundReview.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


