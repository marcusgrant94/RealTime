//
//  SetNameView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//

import SwiftUI
import Firebase

struct SetNameView: View {
    @State private var name = ""
    @EnvironmentObject var usersViewModel: UsersViewModel

    /// Parent’s callback to advance to the next step
    let onSave: (String) -> Void

    var body: some View {
        let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

        ZStack {
            customColor.ignoresSafeArea()

            VStack(spacing: 30) {
                // MARK: Header
                HStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                    Spacer()
                    Button("Help") {
                        // optional help action
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal)

                Spacer()

                // MARK: Prompt
                Text("What's your name?")
                    .font(.title2).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // MARK: Text field
                TextField("Your name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                // MARK: Save button
                Button("Save") {
                    saveName()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
    }

    private func saveName() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users")
          .document(uid)
          .setData(["name": name], merge: true) { error in
            if let error = error {
                print("❌ Error saving name:", error.localizedDescription)
            } else {
                print("✅ Name saved successfully!")
                usersViewModel.fetchCurrentUser()
                // 🏁 Tell the parent flow we’re done
                onSave(name)
            }
        }
    }
}
