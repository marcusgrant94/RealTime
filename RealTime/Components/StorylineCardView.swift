//
//  StorylineCardView.swift
//  RealTime
//
//  Created by Marcus Grant on 3/20/24.
//

import SwiftUI
import SDWebImageSwiftUI  // Don't forget to import SDWebImageSwiftUI

struct StorylineCardView: View {
    var storyline: Storyline
    @EnvironmentObject var usersViewModel: UsersViewModel

    var body: some View {
        // Find the associated user
        let user = usersViewModel.users.first { $0.id == storyline.userId }

        // Use the first story's image as the 'cover image' for the storyline, if available
        let coverImageUrl = storyline.stories.first?.imageUrl

        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.5), Color.black.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                .frame(width: 300, height: 400)
                .shadow(radius: 10)

            VStack {
                HStack {
                    if let imageUrl = user?.imageUrl, let url = URL(string: imageUrl) {
                        WebImage(url: url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 50, height: 50)
                    }

                    VStack(alignment: .leading) {
                        Text(user?.name ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("24 mins ago") // This should ideally reflect the actual creation time of the storyline or the latest story
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding([.top, .horizontal])

                Spacer()

                // Here we use the first story's image as the cover, if it exists
                if let coverImageUrl = coverImageUrl, let url = URL(string: coverImageUrl) {
                    WebImage(url: url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 5)
                } else {
                    // Fallback view if there's no image available
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Spacer()
            }
            .padding()
        }
        .frame(width: 300, height: 400)
    }
}
