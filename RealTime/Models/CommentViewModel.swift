//
//  CommentViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 6/19/25.
//

import Foundation
import Firebase
import FirebaseFirestore


struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var userId: String
    var userName: String
    var timestamp: Timestamp
    var profileImageURL: String?
}


class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    private let db = Firestore.firestore()

    func fetchComments(for captionId: String) {
        db.collection("captions").document(captionId).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.comments = documents.compactMap {
                    try? $0.data(as: Comment.self)
                }
            }
    }

    func postComment(captionId: String, text: String, userId: String, userName: String, profileImageURL: String?) {
        let newComment = Comment(
            text: text,
            userId: userId,
            userName: userName,
            timestamp: Timestamp(date: Date()),
            profileImageURL: profileImageURL
        )

        do {
                let _ = try db.collection("captions")
                    .document(captionId)
                    .collection("comments")
                    .addDocument(from: newComment)
            } catch {
                print("Error posting comment: \(error)")
            }
    }
}


