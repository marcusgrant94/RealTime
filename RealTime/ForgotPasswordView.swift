//
//  ForgotPasswordView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/4/24.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var resetEmail = ""
    @State private var isLoading = false
    @State private var isSent = false
    @State private var errorMessage: String?
    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)
    
    var body: some View {
            NavigationStack {
                ZStack {
                    customColor
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Logo at the top
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 125, height: 125)
                        
                        // Illustration
                        Image("forgotpassword")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 250)
                        
                        Text("Enter your email address to reset your password.")
                            .foregroundColor(.white)
                        
                        // Email text field with icon
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            CustomTextField2(placeholder: Text("Email"), text: $resetEmail)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        
                        // Loading indicator
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.top)
                        }
                        
                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top)
                        }
                        
                        // Success message
                        if isSent {
                            Text("Password reset email has been sent.")
                                .foregroundColor(.green)
                                .padding(.top)
                        }
                        
                        // Forgot Password button
                        Button(action: {
                            isLoading = true
                            errorMessage = nil
                            Auth.auth().sendPasswordReset(withEmail: resetEmail) { error in
                                isLoading = false
                                if let error = error {
                                    errorMessage = error.localizedDescription
                                } else {
                                    isSent = true
                                }
                            }
                        }) {
                            Text("Forgot Password")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                        .padding(.top)
                        .disabled(isLoading)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }

    // Assuming CustomTextField2 is defined as follows with enhancements
    struct CustomTextField2: View {
        var placeholder: Text
        @Binding var text: String
        
        var body: some View {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    placeholder
                        .foregroundColor(.gray)
                }
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
            }
        }
    }

#Preview {
    ForgotPasswordView()
}
