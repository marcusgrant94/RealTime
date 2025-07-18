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
                   VStack(alignment: .leading) {
                       // Logo + subtitle
                       VStack(alignment: .leading) {
                           Image("logo")
                               .resizable()
                               .scaledToFit()
                               .frame(width: 134, height: 135, alignment: .center)
                           Text("Crafted to share life's journey.")
                               .foregroundStyle(.gray)
                               .offset(x: -46, y: -40)
                       }
                       .offset(x: 125, y: 100)

                       // Email field
                       CustomTextField(placeholder: Text("Email"), text: $email)
                           .keyboardType(.emailAddress)
                           .foregroundStyle(.white)
                           .offset(y: 80)
                           .padding()
                           .onChange(of: email) { _ in
                               errorMessage = nil
                           }

                       // Password field
                       CustomTextField(placeholder: Text("Password"), text: $password, isSecure: true)
                           .foregroundStyle(.white)
                           .offset(y: 75)
                           .padding(.horizontal)
                           .onChange(of: password) { _ in
                               errorMessage = nil
                           }

                       // Error message
                       if let errorMessage = errorMessage {
                           Text(errorMessage)
                               .foregroundColor(.red)
                               .padding(.horizontal)
                               .padding(.top, 10)
                               .offset(y: 70)
                       }

                       Spacer()
                   }

                   // Button group
                   VStack {
                       Spacer()

                       // Sign In button
                       Button {
                           isLoading = true
                           authViewModel.signIn(email: email, password: password) { success, error in
                               isLoading = false
                               if success {
                                   errorMessage = nil
                               } else {
                                   errorMessage = error ?? "Incorrect email or password"
                               }
                           }
                       } label: {
                           if isLoading {
                               ProgressView()
                                   .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
                       .padding(.top)
                       .offset(y: 145)
                       .disabled(isLoading)

                       // Divider
                       HStack {
                           Rectangle().frame(width: 75, height: 1).foregroundColor(.gray)
                           Text("Or").padding(.horizontal).foregroundColor(.gray)
                           Rectangle().frame(width: 75, height: 1).foregroundColor(.gray)
                       }
                       .offset(y: 155)

                       // Google Sign In
                       Button(action: googleSignInAction) {
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
                       .offset(y: 170)

                       // Phone Number Sign In
                       NavigationLink(destination: PhoneNumberView()) {
                           Label("Sign in with Phone Number", systemImage: "phone")
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
                       .offset(y: 180)

                       // Forgot Password
                       NavigationLink(destination: ForgotPasswordView()) {
                           Text("Forgot Password?")
                               .foregroundStyle(.gray)
                       }
                       .offset(y: 200)

                       Spacer()

                       // Sign Up link
                       HStack {
                           Text("Don't have an account?").foregroundStyle(.gray)
                           NavigationLink(destination: SignUpView()) {
                               Text("Sign Up").foregroundStyle(.teal)
                           }
                       }
                       .offset(y: -45)
                   }
               }
               .background(customColor)
               .edgesIgnoringSafeArea(.all)
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
}
