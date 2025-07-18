//
//  StoriesViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 1/13/24.
//

import Foundation
import Firebase
import SwiftUI

struct Storyline: Identifiable {
    let id: String // Consider using the document ID from Firestore
    let userId: String
    let created: Date
    let stories: [Story] // Array of Story objects
    var userProfileImage: String
}

struct Story: Identifiable {
    let id: String
    let imageUrl: String
    let userId: String
    let viewers: [Viewer]?
    
    init(id: String, imageUrl: String, userId: String, viewers: [Viewer]? = nil) {
           self.id = id
           self.imageUrl = imageUrl
           self.userId = userId
           self.viewers = viewers
       }
}

struct Viewer: Identifiable {
    let id: String
    let name: String
    let profileImageUrl: String?
}


class StoriesViewModel: ObservableObject {
    @Published var stories = [String: [Story]]()
    @Published var storylines = [String: [Storyline]]()
    private var fetchedUserCount = 0
    private var totalUsersToFetch = 0

    func fetchStories(userId: String) {
        print("Fetching stories for userId: \(userId)")
        let db = Firestore.firestore()
            db.collection("stories")
              .whereField("userId", isEqualTo: userId)
              .order(by: "timestamp", descending: true)
              .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else {
                    print("Error: self is nil when fetching stories for userId: \(userId)")
                    return }
                  
                let userStories: [Story] = querySnapshot?.documents.compactMap { document -> Story? in
                    let data = document.data()
                    let id = document.documentID
                    let imageUrl = data["imageUrl"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    
                    var viewers: [Viewer] = []
                                   if let viewersData = data["viewers"] as? [[String: Any]] {
                                       viewers = viewersData.compactMap { viewerData -> Viewer? in
                                           guard let viewerId = viewerData["id"] as? String,
                                                 let viewerName = viewerData["name"] as? String else { return nil }
                                           let profileImageUrl = viewerData["profileImageUrl"] as? String
                                           return Viewer(id: viewerId, name: viewerName, profileImageUrl: profileImageUrl)
                                       }
                                   }
                    return Story(id: id, imageUrl: imageUrl, userId: userId, viewers: viewers)
                } ?? []

                DispatchQueue.main.async {
                    print("Successfully fetched \(userStories.count) stories for userId: \(userId)")
                    // Assign stories to the user ID key in the dictionary
                    self.stories[userId] = userStories
                    self.fetchedUserCount += 1
                    if self.fetchedUserCount == self.totalUsersToFetch {
                        print("Fetched all user stories.")
                        self.onAllUsersFetched()
                }
            }
        }
    }
    
    func addViewerToStory(storyId: String, viewer: Viewer) {
        let db = Firestore.firestore()
        let storyRef = db.collection("stories").document(storyId)

        storyRef.updateData([
            "viewers": FieldValue.arrayUnion([[
                "id": viewer.id,
                "name": viewer.name,
                "profileImageUrl": viewer.profileImageUrl ?? ""
            ]])
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated with viewer.")
            }
        }
    }
    
    func deleteStory(_ storyId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("stories").document(storyId).delete() { [weak self] error in
            if let error = error {
                print("Error removing story: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Story successfully removed!")
                DispatchQueue.main.async {
                    // Iterate through the dictionary and remove the story from the appropriate user's array
                    for (userId, stories) in self?.stories ?? [:] {
                        if let index = stories.firstIndex(where: { $0.id == storyId }) {
                            self?.stories[userId]?.remove(at: index)
                            break
                        }
                    }
                    completion(true)
                }
            }
        }
    }



    func fetchStoriesForUsers(userIds: [String]) {
        print("Starting to fetch stories for users: \(userIds)")
        fetchedUserCount = 0
        totalUsersToFetch = userIds.count
        stories.removeAll() // Clear existing stories
        for userId in userIds {
            print("Fetching stroeis for userId: \(userId)")
            fetchStories(userId: userId)
        }
    }

    private func onAllUsersFetched() {
        // All user stories have been fetched, you might want to do something here
        print("Fetched all user stories.")
    }
    
    
    func fetchStorylinesForUser(userId: String) {
        let db = Firestore.firestore()
        db.collection("storylines")
            .whereField("userId", isEqualTo: userId)
            .order(by: "created", descending: true)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error getting storylines: \(error.localizedDescription)")
                    return
                }

                var userStorylines: [Storyline] = []
                let group = DispatchGroup()

                querySnapshot?.documents.forEach { document in
                    group.enter() // Start a new group for each document
                    let data = document.data()
                    let id = document.documentID
                    let createdTimestamp = data["created"] as? Timestamp ?? Timestamp()
                    let createdDate = createdTimestamp.dateValue()
                    let stories = (data["stories"] as? [[String: Any]] ?? []).compactMap { storyData -> Story? in
                        guard let storyId = storyData["id"] as? String, let imageUrl = storyData["imageUrl"] as? String else {
                            return nil
                        }
                        return Story(id: storyId, imageUrl: imageUrl, userId: userId)
                    }
                    
                    // Fetch user profile image
                    db.collection("users").document(userId).getDocument { userSnapshot, userError in
                        defer { group.leave() } // Make sure to leave the group whether or not there's an error
                        
                        if let userError = userError {
                            print("Error getting user data: \(userError.localizedDescription)")
                            return
                        }
                        
                        if let userData = userSnapshot?.data(), let userProfileImage = userData["profileImageUrl"] as? String {
                            // Append new storyline including the user's profile image
                            userStorylines.append(Storyline(id: id, userId: userId, created: createdDate, stories: stories, userProfileImage: userProfileImage))
                        }
                    }
                }

                group.notify(queue: .main) {
                    // Once all user profile images have been fetched, update the state
                    self.storylines[userId] = userStorylines
                }
            }
    }
    
    func fetchStorylinesForFriends(friends: [User]) {
        storylines.removeAll() // Clear existing storylines
        for friend in friends {
            fetchStorylinesForUser(userId: friend.id)
        }
    }
}




