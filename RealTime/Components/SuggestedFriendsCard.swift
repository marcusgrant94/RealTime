//
//  SuggestedFriendsCard.swift
//  RealTime
//
//  Created by Marcus Grant on 7/1/25.
//

import SwiftUI

struct SuggestedFriendsCard: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    let user: User

    @State private var isAdded = false

    var body: some View {
        VStack(spacing: 12) {
            // Profile image
            if let url = user.imageUrl, !url.isEmpty {
                AsyncImageView(url: url)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            }

            // Name
            Text(user.name)
                .font(.headline)
                .multilineTextAlignment(.center)

            // Add-friend button
            Button(action: addFriend) {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text(isAdded ? "Added" : "Add")
                }
                .font(.subheadline)
                .foregroundColor(.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            .disabled(isAdded)
            .opacity(isAdded ? 0.6 : 1)
        }
        .padding()
        .frame(width: 140)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func addFriend() {
        guard !isAdded,
              let currentUser = usersViewModel.currentUser else { return }

        usersViewModel.addFriend(
            toUserID: currentUser.id,
            friendID: user.id
        )
        isAdded = true
    }
}
