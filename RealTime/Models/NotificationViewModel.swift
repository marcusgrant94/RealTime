//
//  NotificationViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 7/27/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var type: String
    var userId: String        // receiver
    var fromUserId: String    // sender (the person who liked or added)
    var captionId: String?
    var timestamp: Timestamp
    var username: String?
    
    init(id: String? = nil, type: String, userId: String, fromUserId: String, captionId: String, timestamp: Timestamp = Timestamp(), username: String? = nil) {
        self.id = id
        self.type = type
        self.userId = userId
        self.captionId = captionId
        self.timestamp = timestamp
        self.username = username
        self.fromUserId = fromUserId
    }
}


class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    private var db = Firestore.firestore()
    private var usersViewModel: UsersViewModel
    
    init(usersViewModel: UsersViewModel) {
        self.usersViewModel = usersViewModel
    }
    
    func fetchNotifications() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("notifications")
            .whereField("userId", isEqualTo: currentUserID)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    return
                }
                
                var fetchedNotifications: [AppNotification] = []
                
                snapshot?.documents.forEach { document in
                    if var notification = try? document.data(as: AppNotification.self) {
                        if let user = self.usersViewModel.users.first(where: { $0.id == notification.fromUserId }) {
                            notification.username = user.name
                        } else {
                            notification.username = "Someone" // Fallback if user not found
                        }
                        fetchedNotifications.append(notification)
                    }
                }
                
                DispatchQueue.main.async {
                    self.notifications = fetchedNotifications
                }
            }
    }
    
    func deleteNotification(forCaptionId captionId: String, userId: String) {
        db.collection("notifications")
            .whereField("captionId", isEqualTo: captionId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error deleting notification: \(error)")
                    return
                }
                
                querySnapshot?.documents.forEach { document in
                    self.db.collection("notifications").document(document.documentID).delete { error in
                        if let error = error {
                            print("Failed to delete notification: \(error)")
                        }
                    }
                }
            }
    }
    
    func deleteNotificationById(notificationId: String?) {
        guard let id = notificationId else { return }
        
        db.collection("notifications").document(id).delete { error in
            if let error = error {
                print("Failed to delete notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.notifications.removeAll {$0.id == notificationId }
                }
            }
        }
    }
}


