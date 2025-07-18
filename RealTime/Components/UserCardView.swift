//
//  UserCardView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/28/25.
//

import SwiftUI

struct UserCardView: View {
    var user: User

    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = user.imageUrl, !imageUrl.isEmpty {
                AsyncImageView(url: imageUrl)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }

            Text(user.name)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

