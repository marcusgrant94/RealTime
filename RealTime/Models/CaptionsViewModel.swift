//
//  CaptionsViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 6/2/24.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import Combine


struct Caption: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var userId: String
    var timestamp: Timestamp
    var userName: String
    var profileImageURL: String?
    var likedBy: [String]
    var commentCount: Int?
    var captionImageURL: String?
    
    var likeCount: Int {
            likedBy.count
        }
    
    
    init(id: String? = nil, text: String, userId: String, timestamp: Timestamp = Timestamp(), userName: String?, profileImageURL: String? = nil, likedBy: [String], captionImageURL: String? = nil) {
        self.id = id
        self.text = text
        self.userId = userId
        self.timestamp = timestamp
        self.userName = userName ?? " "
        self.profileImageURL = profileImageURL
        self.likedBy = likedBy
        self.captionImageURL = captionImageURL
    }
    var liked: Bool {
            // Check if the current user has liked the caption
            guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
            return likedBy.contains(currentUserID)
        }
}




class CaptionsViewModel: ObservableObject {
    @Published var captions: [Caption] = []
    private var db = Firestore.firestore()
    
    func fetchCaptions(for currentUserId: String, friends: [String]) {
        print("Fetching captions from Firestore")
        db.collection("captions")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching captions: \(error)")
                    return
                }

                var newCaptions: [Caption] = []
                let group = DispatchGroup()

                for document in snapshot?.documents ?? [] {
                    guard var caption = try? document.data(as: Caption.self),
                          let captionId = caption.id else { continue }

                    let userId = caption.userId
                    guard friends.contains(userId) || userId == currentUserId else { continue }

                    group.enter()
                    self.db.collection("users").document(userId).getDocument { userDoc, _ in
                        if let data = userDoc?.data() {
                            caption.userName = data["name"] as? String ?? "Unknown User"
                            caption.profileImageURL = data["profileImageURL"] as? String
                        }

                        self.db.collection("captions").document(captionId).collection("comments").getDocuments { commentSnapshot, _ in
                            caption.commentCount = commentSnapshot?.documents.count ?? 0

                            DispatchQueue.main.async {
                                newCaptions.append(caption)
                                group.leave()
                            }
                        }
                    }
                }


                group.notify(queue: .main) {
                    self.captions = newCaptions.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    print("📦 Final captions with comment counts: \(self.captions.map { "\($0.text): \($0.commentCount ?? 0)" })")
                }
            }
    }
    
    @Published var publicCaptions: [Caption] = []

    func fetchCaptionsForUserProfile(userId: String) {
        print("📥 Fetching captions for public profile: \(userId)")
        db.collection("captions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching user's captions: \(error)")
                    return
                }

                var captions: [Caption] = []
                let group = DispatchGroup()

                for document in snapshot?.documents ?? [] {
                    guard var caption = try? document.data(as: Caption.self),
                          let captionId = caption.id else { continue }

                    group.enter()
                    self.db.collection("users").document(userId).getDocument { userDoc, _ in
                        if let data = userDoc?.data() {
                            caption.userName = data["name"] as? String ?? "Unknown User"
                            caption.profileImageURL = data["profileImageURL"] as? String
                        }

                        self.db.collection("captions").document(captionId).collection("comments").getDocuments { commentSnapshot, _ in
                            caption.commentCount = commentSnapshot?.documents.count ?? 0

                            DispatchQueue.main.async {
                                captions.append(caption)
                                group.leave()
                            }
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.publicCaptions = captions
                    print("✅ Loaded public profile captions: \(captions.count)")
                }
            }
    }




    
    func postCaption(
        text: String,
        userId: String,
        userName: String,
        profileImageURL: String?,
        captionImageURL: String? = nil
    ) {
        let caption = Caption(
            text: text,
            userId: userId,
            userName: userName,
            profileImageURL: profileImageURL,
            likedBy: [],
            captionImageURL: captionImageURL
        )

        print("Posting caption: \(caption)")

        do {
            let _ = try db.collection("captions").addDocument(from: caption) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Document added successfully")
                }
            }
        } catch {
            print("Error posting caption: \(error)")
        }
    }

    
    func toggleLike(caption: Caption) {
        guard let id = caption.id, let currentUserID = Auth.auth().currentUser?.uid else { return }
        var updatedLikedBy = caption.likedBy
        let originalLikedBy = caption.likedBy // Store original state for potential revert

        if caption.liked {
            updatedLikedBy.removeAll { $0 == currentUserID }
            deleteNotification(caption: caption)
        } else {
            updatedLikedBy.append(currentUserID)
            createNotification(caption: caption)
        }

        // Update local state immediately
        if let index = self.captions.firstIndex(where: { $0.id == caption.id }) {
            self.captions[index].likedBy = updatedLikedBy
            // Trigger UI update explicitly if needed (though usually not necessary)
            // self.objectWillChange.send()

            // Update Firestore
            db.collection("captions").document(id).updateData(["likedBy": updatedLikedBy]) { error in
                if let error = error {
                    print("Error updating like state: \(error)")
                    // Revert local state on failure
                    self.captions[index].likedBy = originalLikedBy
                }
            }
        }
    }

    
    func deleteCaption(_ caption: Caption) {
        guard let id = caption.id else { return }
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // Check if the current user is the owner of the post
        guard caption.userId == currentUserID else {
            print("Error: Only the owner of the caption can delete it.")
            return
        }
        
        // Proceed to delete if the user is the owner
        db.collection("captions").document(id).delete { error in
            if let error = error {
                print("Error deleting caption: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.captions.removeAll { $0.id == caption.id }
                    self.publicCaptions.removeAll { $0.id == caption.id }
                }
            }
        }
    }
    
    private func createNotification(caption: Caption) {
        guard let captionId = caption.id else { return }
        guard let fromUserId = Auth.auth().currentUser?.uid else { return }
        let toUserId = caption.userId  // Who should receive the notification

        // Don't notify yourself
        guard fromUserId != toUserId else { return }

        let notification = AppNotification(
            type: "like",
            userId: toUserId,            // receiver
            fromUserId: fromUserId, captionId: captionId,      // sender
            timestamp: Timestamp()
        )

        do {
            let _ = try db.collection("notifications").addDocument(from: notification)
        } catch {
            print("Error creating notification: \(error)")
        }
    }

    
    private func deleteNotification(caption: Caption) {
        guard let captionId = caption.id, let currentUserID = Auth.auth().currentUser?.uid else { return }

        db.collection("notifications")
            .whereField("type", isEqualTo: "like")
            .whereField("captionId", isEqualTo: captionId)
            .whereField("userId", isEqualTo: currentUserID)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching notification to delete: \(error)")
                    return
                }

                querySnapshot?.documents.forEach { document in
                    self.db.collection("notifications").document(document.documentID).delete { error in
                        if let error = error {
                            print("Error deleting notification: \(error)")
                        }
                    }
                }
            }
    }
    
    func flagCaption(_ caption: Caption, reason: String = "unspecified") {
            guard let captionId = caption.id,
                  let reporterId = Auth.auth().currentUser?.uid else {
                print("⚠️ Cannot flag: missing caption ID or user not signed in")
                return
            }

            let reportData: [String: Any] = [
                "captionId":   captionId,
                "reporterId":  reporterId,
                "reason":      reason,
                "timestamp":   Timestamp()
            ]

            db.collection("captionReports").addDocument(data: reportData) { error in
                if let error = error {
                    print("❌ Error reporting caption \(captionId): \(error)")
                } else {
                    print("✅ Report submitted for caption \(captionId)")
                }
            }
        }
    }
