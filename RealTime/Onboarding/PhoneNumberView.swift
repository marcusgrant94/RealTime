//
//  PhoneNumberView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//

import SwiftUI

struct PhoneNumberView: View {
    @State private var phoneNumber = ""
    @State private var showingCountryPicker = false
    @State private var selectedCountryCode = "+1"
    @State private var myCountry = Country(name: "United States",
                                              flag: "🇺🇸",
                                              code: "+1")
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigateToVerification = false
    

    var body: some View {
        let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)

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
            Text("What's your phone number?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Phone input
            HStack {
                // Country code placeholder
                HStack(spacing: 5) {
                    Button(action: {
                        showingCountryPicker = true
                    }) {
                        HStack {
                            Text(myCountry.flag)
                            Text(myCountry.code)
                            .foregroundColor(.white)
                        }
                    }
                    .sheet(isPresented: $showingCountryPicker) {
                      CountryPicker(selectedCountry: $myCountry)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)

                TextField("Your phone number", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)

            // Policy note
            Text("By continuing, you agree to our Privacy Policy and Terms of Service.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            // Send verification button
            Button(action: {
                let phoneNumberWithCode = selectedCountryCode + phoneNumber
                authViewModel.sendVerificationText(phoneNumberWithCode: phoneNumberWithCode) { success, error in
                    if success {
                        navigateToVerification = true
                    } else {
                        // Show error alert
                    }
                }
            }) {
                Text("Send Verification Text")
            }
            .padding(.horizontal)
            .disabled(phoneNumber.isEmpty)
            .opacity(phoneNumber.isEmpty ? 0.5 : 1.0)
            
            NavigationLink(
                   destination: VerificationCodeView(),
                   isActive: $navigateToVerification,
                   label: { EmptyView() }
               )

            Spacer()
        }
        .padding(.top)
        .background(customColor.edgesIgnoringSafeArea(.all))
    }

    private func sendVerificationText() {
        // 🔥 Implement Firebase phone auth logic here later
        print("Sending verification text to \(phoneNumber)")
    }
}


#Preview {
    PhoneNumberView()
        .environmentObject(UsersViewModel())
}
