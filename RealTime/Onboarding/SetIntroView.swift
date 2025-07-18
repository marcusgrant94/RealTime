//
//  SetIntroView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//

import SwiftUI
import Firebase


struct SetIntroView: View {
    @State private var bioText = ""

    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Parent’s callback to move to the next step
    let onSave: () -> Void

    var body: some View {
        let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

        ZStack {
            customColor.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("Write a short bio to tell others about yourself…")
                    .font(.title2)
                    .foregroundColor(.white)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: 150)

                    TextEditor(text: $bioText)
                        .foregroundColor(.white)
                        .padding(8)
                        .frame(height: 150)
                        .scrollContentBackground(.hidden)
                }
                .padding(.horizontal)

                Button("Save and Continue") {
                    saveBio()
                }
                .disabled(bioText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .foregroundColor(.black)
                .frame(width: 250)
                .padding()
                .background(Color.gray)
                .cornerRadius(12)

                Spacer()
            }
            .padding(.top)
        }
    }

    private func saveBio() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "bio": bioText,
            "onboardingCompleted": false // we’ll complete after sync
        ]

        Firestore
          .firestore()
          .collection("users")
          .document(uid)
          .setData(data, merge: true) { error in
            if let error = error {
                print("❌ Failed to save bio:", error)
            } else {
                usersViewModel.fetchCurrentUser()
                onSave()   // tell parent to go to the next step
            }
          }
    }
}
