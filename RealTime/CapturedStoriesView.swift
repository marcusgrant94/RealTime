//
//  CapturedStoriesView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/8/24.
//

import SwiftUI
import Firebase

struct CapturedStoriesView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @StateObject var viewModel = StoriesViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                customColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let userId = authViewModel.currentUserId,
                           let userStories = viewModel.stories[userId], !userStories.isEmpty {
                            ForEach(userStories) { story in
                                StoryCardView(story: story) {
                                    viewModel.deleteStory(story.id) { success in
                                        if success {
                                            // Remove locally so view updates immediately
                                            viewModel.stories[userId]?.removeAll { $0.id == story.id }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Text("No stories available")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        }

                        Spacer(minLength: 50) // breathing room at the bottom
                    }
                }
                .onAppear {
                    if let userId = authViewModel.currentUserId {
                        viewModel.fetchStories(userId: userId)
                    }
                }
                .navigationTitle("My Stories")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}


struct StoryCardView: View {
    let story: Story
    let onDelete: () -> Void  // passed from parent

    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @EnvironmentObject var viewModel: StoriesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: story.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                @unknown default:
                    EmptyView()
                }
            }

            if authViewModel.currentUserId == story.userId {
                Button(action: {
                    onDelete()
                }) {
                    Text("Delete Story")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if let viewers = story.viewers, !viewers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Viewed by")
                        .font(.headline)
                        .padding(.top, 8)
                        .foregroundColor(.white)

                    ForEach(viewers, id: \.id) { viewer in
                        HStack {
                            if let urlStr = viewer.profileImageUrl,
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 36, height: 36)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 36, height: 36)
                                            .clipShape(Circle())
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 36, height: 36)
                                            .clipShape(Circle())
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .foregroundColor(.gray)
                            }

                            Text(viewer.name)
                                .font(.subheadline)
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .background(customColor.opacity(0.95))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


