//
//  SignUpView.swift
//  RealTime
//
//  Created by Marcus Grant on 11/20/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SignUpView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel
    var isSecure: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    
    var body: some View {
            GeometryReader { geometry in
                NavigationStack {
                    ZStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: geometry.size.width * 0.04) {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: min(geometry.size.width * 0.35, 150), height: min(geometry.size.width * 0.35, 150))
                                    .padding(.bottom, geometry.size.width * 0.02)
                                    .offset(y: 18)
                                
                                Text("Create account to continue!")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(.gray)
                                    .dynamicTypeSize(.medium)
                                
                                CustomTextField(placeholder: Text("Full Name"), text: $fullName)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, geometry.size.width * 0.01)
                                
                                CustomTextField(placeholder: Text("Email"), text: $email)
                                    .foregroundStyle(.white)
                                    .keyboardType(.emailAddress)
                                    .padding(.vertical, geometry.size.width * 0.01)
                                
                                CustomTextField(placeholder: Text("Password"), text: $password, isSecure: true)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, geometry.size.width * 0.01)
                                
                                CustomTextField(placeholder: Text("Confirm Password"), text: $confirmPassword, isSecure: true)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, geometry.size.width * 0.01)
                                
                                if let errorMessage = errorMessage {
                                                                Text(errorMessage)
                                                                    .foregroundColor(.red)
                                                                    .font(.system(.subheadline, design: .rounded))
                                                                    .dynamicTypeSize(.large)
                                                                    .padding(.top, geometry.size.width * 0.02)
                                                            }
                                                        }
                                                        .padding(.horizontal, horizontalSizeClass == .regular ? geometry.size.width * 0.1 : geometry.size.width * 0.05)
                                                        .padding(.top, geometry.size.height * 0.05)
                            
                            VStack(spacing: geometry.size.width * 0.05) {
                                Button(action: signUpAction) {
                                    Text("Create Account")
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: horizontalSizeClass == .regular ? geometry.size.width * 0.6 : .infinity)
                                        .background(Color.gray)
                                        .cornerRadius(10)
                                        .shadow(radius: 10)
                                        .font(.system(.headline, design: .rounded, weight: .semibold))
                                        .dynamicTypeSize(.large)
                                }
                                
                                HStack {
                                                                Rectangle()
                                                                    .frame(width: geometry.size.width * 0.2, height: 1)
                                                                    .foregroundColor(.gray)
                                                                Text("Or")
                                                                    .padding(.horizontal)
                                                                    .foregroundColor(.gray)
                                                                    .font(.system(.headline, design: .rounded))
                                                                    .dynamicTypeSize(.large)
                                                                Rectangle()
                                                                    .frame(width: geometry.size.width * 0.2, height: 1)
                                                                    .foregroundColor(.gray)
                                                            }
                                
                                HStack(spacing: geometry.size.width * 0.08) {
                                    // Google
                                    Button(action: googleSignUpAction) {
                                        Image("googlelogo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: min(geometry.size.width * 0.08, 30), height: min(geometry.size.width * 0.08, 30))
                                            .padding(geometry.size.width * 0.03)
                                    }
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                                    
                                    // Phone
                                    NavigationLink {
                                        PhoneNumberView()
                                            .environmentObject(authViewModel)
                                    } label: {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: min(geometry.size.width * 0.08, 30)))
                                            .foregroundColor(.white)
                                            .padding(geometry.size.width * 0.03)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    }
                                    
                                    // Apple
                                    Button(action: appleSignUpAction) {
                                        Image(systemName: "applelogo")
                                            .font(.system(size: min(geometry.size.width * 0.08, 30)))
                                            .foregroundColor(.white)
                                            .padding(geometry.size.width * 0.03)
                                    }
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                }
                                
                                HStack {
                                                                Text("I have an account,")
                                                                    .foregroundStyle(.gray)
                                                                    .font(.system(.subheadline, design: .rounded))
                                                                    .dynamicTypeSize(.xLarge)
                                                                NavigationLink(destination: SignInView()) {
                                                                    Text("Sign in")
                                                                        .foregroundStyle(.teal)
                                                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                                        .dynamicTypeSize(.xLarge)
                                                                }
                                                            }
                                                        }
                                                        .padding(.horizontal, horizontalSizeClass == .regular ? geometry.size.width * 0.1 : geometry.size.width * 0.05)
                                                        .padding(.top, geometry.size.width * 0.05)
                                                    }
                        .background(customColor)
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
        }
    
    private func googleSignUpAction() {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            authViewModel.signUpWithGoogle(presentingViewController: rootViewController)
        }
    }
    
    private func appleSignUpAction() {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            authViewModel.signInWithApple()
        }
    }

        private func signUpAction() {
            // Add your sign-up logic here
            if password == confirmPassword {
                if password.count >= 6 {
                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                        if let error = error {
                            print("Error occurred: \(error.localizedDescription)")
                            errorMessage = error.localizedDescription
                        } else {
                            print("User signed up successfully.")
                            errorMessage = nil
                            
                            // Create Firestore user document
                            if let authUser = authResult?.user {
                                let userData = [
                                    "id": authUser.uid,
                                    "email": email,
                                    "role": "user",  // Change this if you need different roles
                                    "name": fullName
                                ]
                                
                                Firestore.firestore().collection("users").document(authUser.uid).setData(userData) { error in
                                    if let error = error {
                                        print("Error occurred: \(error.localizedDescription)")
                                    } else {
                                        print("User document created successfully.")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    errorMessage = "Password should be at least 6 characters long."
                }
            } else {
                errorMessage = "Passwords do not match."
            }
        }
    }
    
    #Preview {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
    
