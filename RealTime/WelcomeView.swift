//
//  WelcomeView.swift
//  RealTime
//
//  Created by Marcus Grant on 7/10/24.
//

import SwiftUI

struct WelcomeView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isShowingGoogleSignIn = false
    @EnvironmentObject var authViewModel: AuthViewModel
    var isSecure: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    customColor
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        // Top content: logo and tagline
                        VStack {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.3)
                            Text("Crafted to share life's journey.")
                                .offset(y: -68)
                                .foregroundStyle(.gray)
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                        
                        Spacer()
                        
                        // Bottom content: legal links and buttons
                        VStack {
                            LegalLinksView()
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 12))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: geometry.size.width * 0.8)
                            
                            NavigationLink(destination: SignUpView()) {
                                Text("Create Account")
                                    .foregroundColor(.black)
                                    .frame(minWidth: 0, maxWidth: geometry.size.width * 0.5)
                                    .padding()
                                    .background(Color.gray)
                                    .cornerRadius(30)
                                    .shadow(radius: 10)
                            }
                            .padding(.vertical, 10)
                            
                            NavigationLink(destination: SignInView()) {
                                Text("Sign In")
                                    .foregroundStyle(.gray)
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
                .background(customColor)
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

#Preview {
    WelcomeView()
}
