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
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 134, height: 135)
                        Text("Create account to continue!").font(.subheadline)
                            .foregroundStyle(.gray)
                        
                        CustomTextField(placeholder: Text("Full Name"), text: $fullName).foregroundStyle(.white)
                        CustomTextField(placeholder: Text("Email"), text: $email).foregroundStyle(.white)
                            .keyboardType(.emailAddress)
                        CustomTextField(placeholder: Text("Password"), text: $password, isSecure: true).foregroundStyle(.white)
                        CustomTextField(placeholder: Text("Confirm Password"), text: $confirmPassword, isSecure: true).foregroundStyle(.white)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        Button(action: signUpAction) {
                            Text("Create Account")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                        
                        HStack {
                            Rectangle().frame(width: 75, height: 1).foregroundColor(.gray)
                            Text("Or").padding(.horizontal).foregroundColor(.gray)
                            Rectangle().frame(width: 75, height: 1).foregroundColor(.gray)
                        }
                        
                        Button(action: googleSignUpAction) {
                            HStack {
                                Image("googlelogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28)
                                Text("Continue With Google")
                            }
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: 350)
                            .background(Color.white)
                            .cornerRadius(8.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8.0)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                        }
                        
                        NavigationLink(destination: PhoneNumberView()) {
                            Label("Sign up with Phone Number", systemImage: "phone")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 350)
                        .background(Color.clear)
                        .cornerRadius(8.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8.0)
                                .stroke(Color.white, lineWidth: 1)
                        )

                        
                        HStack {
                            Text("I have an account,").foregroundStyle(.gray)
                            NavigationLink(destination: SignInView()) {
                                Text("Sign in").foregroundStyle(.teal)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .background(customColor)
            .edgesIgnoringSafeArea(.all)
        }
        }
    
    private func googleSignUpAction() {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            authViewModel.signUpWithGoogle(presentingViewController: rootViewController)
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
    
