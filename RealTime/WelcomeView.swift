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
            NavigationStack {
                ZStack {
                    customColor
                        .edgesIgnoringSafeArea(.all)
                    VStack(alignment: .center) {
                        
                        VStack(alignment: .center) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 134, height: 360, alignment: .center)
                            Text("Crafted to share life's journey.")
                                .offset(y: -155)
                                .foregroundStyle(.gray)
                                
                        }
                       
                        
                        
                        
                        Spacer()
                        
                    }
                    .padding(.top, 5)
                    
                    VStack {
                        
                        Spacer()
                        
                        
                        Text("By selecting Create Account, you agree to our Terms of Service. Learn more about how we process your data in our Private Policy")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .offset(y: 269)
                        
                        
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Create Account")
                                .foregroundColor(.black)
                                .frame(minWidth: 0, maxWidth: 190)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(30)
                                .shadow(radius: 10)
                        }
                        .offset(y: 290)
//                            NavigationLink (destination: SignUpView()) {
//                                Text("Sign Up")
//                                    .foregroundStyle(.gray)
//                        }
//                        .offset(y: 270)
                        NavigationLink(destination: SignInView()) {
                            Text("Sign In")
                                .foregroundStyle(.gray)
                        }
                        .offset(y: 300)
                        Spacer()
                        
                    }
                }
                .background(customColor)
                .edgesIgnoringSafeArea(.all)
            }
            
            
        }
}

#Preview {
    WelcomeView()
}
