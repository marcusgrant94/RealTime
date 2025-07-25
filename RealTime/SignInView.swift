//
//  SignInView.swift
//  RealTime
//
//  Created by Marcus Grant on 11/20/23.
//

import SwiftUI

struct SignInView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false // New state for loading indicator
    @State private var isShowingGoogleSignIn = false
    @EnvironmentObject var authViewModel: AuthViewModel
    var isSecure: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                customColor
                    .ignoresSafeArea()

                VStack(alignment: .center, spacing: 1) {
                    // MARK: Logo + Subtitle
                    VStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 134, height: 135)
                        Text("Crafted to share life's journey.")
                            .foregroundStyle(.gray)
                            .offset(y: -43)
                    }

                    // MARK: Email field
                    CustomTextField(placeholder: Text("Email"), text: $email)
                        .keyboardType(.emailAddress)
                        .foregroundStyle(.white)
                        .padding()
                        .onChange(of: email) { _ in errorMessage = nil }
                        .padding(.horizontal)

                    // MARK: Password field
                    CustomTextField(placeholder: Text("Password"),
                                    text: $password,
                                    isSecure: true)
                        .foregroundStyle(.white)
                        .padding()
                        .onChange(of: password) { _ in errorMessage = nil }
                        .padding(.horizontal)

                    // MARK: Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                    // MARK: Sign In button
                    Button {
                        isLoading = true
                        authViewModel.signIn(email: email, password: password) { success, error in
                            isLoading = false
                            errorMessage = success
                                ? nil
                                : (error ?? "Incorrect email or password")
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: .white)
                                )
                        } else {
                            Text("Sign In")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: 350)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                    }
                    .padding(.top, 20)
                    .disabled(isLoading)

                    // MARK: “Or” divider
                    HStack {
                        Rectangle()
                            .frame(width: 75, height: 1)
                            .foregroundColor(.gray)
                        Text("Or")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        Rectangle()
                            .frame(width: 75, height: 1)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    // MARK: Social / Phone / Apple icons
                    HStack(spacing: 30) {
                        // Google
                        Button(action: googleSignInAction) {
                            Image("googlelogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(10)
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
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(10)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: 1)
                                )
                        }

                        // Apple
                        Button(action: appleSignUpAction) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 1)
                        )
                    }
                    .padding(.top, 20)

                    // MARK: Forgot Password
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .foregroundStyle(.gray)
                    }
                    .offset(y: -15)
                    .padding(.top, 50)

                    Spacer()

                    // MARK: Sign Up link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(.gray)
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }

    
    private func googleSignInAction() {
        if let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController {
            authViewModel.signInWithGoogle(presentingViewController: rootVC)
        }
    }
    
    private func appleSignUpAction() {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            authViewModel.signInWithApple()
        }
    }
}

struct CustomTextField3: View {
    var placeholder: Text
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
                    .foregroundColor(.gray)
            }
            if isSecure {
                SecureField("", text: $text)
                    .foregroundColor(.white)
            } else {
                TextField("", text: $text)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
