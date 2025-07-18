//
//  VerificationCodeView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//

import SwiftUI
import FirebaseAuth
import Firebase

struct VerificationCodeView: View {
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var navigateToSetName = false
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        let customColor = Color(red: 22/255.0, green: 29/255.0, blue: 35/255.0)

        VStack(spacing: 30) {
            // Top app title and help
            HStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 34)

                Spacer()

                Button("Help") {
                    // 🔥 Implement help action
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal)

            Spacer()

            // Title prompt
            Text("Enter the verification code")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Code input
            TextField("6-digit code", text: $verificationCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal)

            // Verify button or loader
            if isLoading {
                ProgressView("Verifying...")
                    .foregroundColor(.white)
            } else {
                Button(action: {
                    verifyCode()
                }) {
                    Text("Verify and Sign In")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(verificationCode.isEmpty)
                .opacity(verificationCode.isEmpty ? 0.5 : 1.0)
            }

            Spacer()

            // NavigationLink to SetNameView
            NavigationLink(destination: SetNameView { name in
                print("User set name: \(name)")
                // 🔥 Continue onboarding here (SetProfilePicView)
            }, isActive: $navigateToSetName) {
                EmptyView()
            }
        }
        .padding(.top)
        .background(customColor.edgesIgnoringSafeArea(.all))
    }

    private func verifyCode() {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            print("❌ No verification ID found.")
            return
        }

        isLoading = true

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            isLoading = false

            if let error = error {
                print("❌ Error signing in with code: \(error.localizedDescription)")
            } else {
                print("✅ Phone authentication successful!")

                if let userId = authResult?.user.uid {
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(userId)

                    userRef.getDocument { document, error in
                        if let document = document, document.exists {
                            print("✅ User document already exists")

                            // Fetch current user data
                            usersViewModel.fetchCurrentUser()

                            // Navigate based on current user data
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let user = usersViewModel.currentUser {
                                    if user.name.isEmpty {
                                        navigateToSetName = true
                                    } else {
                                        // User already has name, skip to TabBar or next step
                                        navigateToSetName = false
                                    }
                                } else {
                                    navigateToSetName = true
                                }
                            }

                        } else {
                            // Create new user document
                            userRef.setData([
                                "id": userId,
                                "name": "",
                                "imageUrl": "",
                                "bio": "",
                                "email": authResult?.user.phoneNumber ?? "",
                                "role": "user",
                                "onboardingCompleted": false
                            ]) { error in
                                if let error = error {
                                    print("❌ Failed to create user document: \(error.localizedDescription)")
                                } else {
                                    print("✅ User document created successfully")
                                    usersViewModel.fetchCurrentUser()
                                    navigateToSetName = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



