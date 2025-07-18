//
//  MatchesFoundView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/28/25.
//

import SwiftUI

struct MatchesFoundView: View {
    var matchedUsers: [User]

    var body: some View {
        let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)

        VStack(spacing: 20) {
            Text("Friends Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top)

            if matchedUsers.isEmpty {
                Text("No contacts found on RealTime yet. Invite your friends!")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(matchedUsers) { user in
                            UserCardView(user: user)
                        }
                    }
                }
            }

            Spacer()
        }
        .background(customColor.edgesIgnoringSafeArea(.all))
    }
}
