//
//  StoriesView.swift
//  RealTime
//
//  Created by Marcus Grant on 11/22/23.
//

import SwiftUI


struct StoriesView: View {
    @ObservedObject var storiesViewModel: StoriesViewModel
    @ObservedObject var usersViewModel:  UsersViewModel
    @State private var presentingStoryDetail = false
    @State private var selectedStory: Story?
    @State private var selectedUserStories: [Story]?

    var body: some View {
           NavigationStack {
               ScrollView {
                   VStack(alignment: .leading, spacing: 0) {
                       Text("Friends")
                           .font(.headline)
                           .padding(.horizontal)
                       
                       ScrollView(.horizontal, showsIndicators: false) {
                           LazyHStack(spacing: 15) {
                               // Explicitly specify the data type for the ForEach loop
                               ForEach(usersViewModel.friends, id: \.id) { (friend: User) in
                                   if let stories = storiesViewModel.stories[friend.id], !stories.isEmpty {
                                       Button(action: {
                                           selectedUserStories = stories
                                           presentingStoryDetail = true
                                       }) {
                                           StoryThumbnailView(friend: friend, stories: stories)
                                       }
                                   }
                               }
                           }
                           .padding(.horizontal)
                           .frame(height: 80)
                       }
                       .edgesIgnoringSafeArea(.horizontal)
                    }
                    .refreshable {
                        refreshStories()
                    }
                }
            .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gear")
                                        .foregroundStyle(.black)
                                }
                            }
                        }
            .refreshable {
                refreshStories()
            }
            .sheet(isPresented: $presentingStoryDetail) {
                if let stories = selectedUserStories {
                    StoriesCarouselView(stories: stories)
                }
            }
        }
           .onAppear {
               usersViewModel.fetchCurrentUser() // If needed, fetch current user data first.
               usersViewModel.fetchFriendsForCurrentUser { // Now expecting a completion block.
                   // This code block is executed after friends are fetched successfully.
                   DispatchQueue.main.async { // Ensure UI updates are on the main thread.
                       let friendIds = usersViewModel.friends.map { $0.id }
                       storiesViewModel.fetchStoriesForUsers(userIds: friendIds)
                       // Add additional functions here if needed, for example fetching storylines.
                   }
               }
           }
    }
    
    private func getUserName(userId: String) -> String {
            usersViewModel.friends.first { $0.id == userId }?.name ?? "Unknown"
        }
    
    private func refreshStories() {
        usersViewModel.fetchFriendsForCurrentUser { // Notice the completion handler being added
            // This block is executed after the friends are successfully fetched.
            let friendIds = usersViewModel.friends.map { $0.id }
            storiesViewModel.fetchStoriesForUsers(userIds: friendIds)
            // If fetchStorylinesForFriends is needed here, add it similarly.
        }
    }

    }



//#Preview {
//    StoriesView()
//}
