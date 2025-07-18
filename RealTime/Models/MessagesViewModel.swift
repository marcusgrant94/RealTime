//
//  MessagesViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 1/18/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI
import FirebaseStorage

class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private var db = Firestore.firestore()
     var currentUserId: String // Current user's ID
     var chatPartnerId: String // Chat partner's ID

    init(currentUserId: String, chatPartnerId: String) {
        self.currentUserId = currentUserId
        self.chatPartnerId = chatPartnerId
        fetchMessages()
    }
    
    func fetchMessages() {
        db.collection("messages")
            .whereField("senderId", in: [currentUserId, chatPartnerId])
            .whereField("recipientId", in: [currentUserId, chatPartnerId])
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.messages = documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as: Message.self)
                }
            }
    }
    
    func sendMessage(_ messageContent: String, senderName: String) {
        let newMessage = Message(
            senderId: currentUserId,
            senderName: senderName,
            recipientId: chatPartnerId,
            text: messageContent,
            imageURL: nil,
            timestamp: Timestamp()
        )
        
        db.collection("messages").addDocument(data: [
                "senderId": newMessage.senderId,
                "senderName": newMessage.senderName, // Make sure to add this line
                "recipientId": newMessage.recipientId,
                "text": newMessage.text,
                "imageURL": newMessage.imageURL as Any,
                "timestamp": newMessage.timestamp
            ]) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
    }

}



struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var recipientId: String
    var text: String
    var imageURL: String?
    var timestamp: Timestamp
}


extension MessagesViewModel {
    /// Uploads the image to Storage then sends a message with imageURL set.
    func sendImage(_ image: UIImage, senderName: String) {
      guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

      // 1️⃣ Create a unique filename
      let filename = UUID().uuidString + ".jpg"
      let storageRef = Storage.storage().reference().child("chat_images/\(filename)")

      // 2️⃣ Upload the JPEG
      storageRef.putData(imageData, metadata: nil) { _, error in
        if let error = error {
          print("❌ Image upload failed:", error)
          return
        }

        // 3️⃣ Fetch the download URL
        storageRef.downloadURL { url, error in
          if let error = error {
            print("❌ Failed to get image URL:", error)
            return
          }
          guard let url = url else { return }

          // 4️⃣ Send a message with the imageURL
          let data: [String: Any] = [
            "senderId":        self.currentUserId,
            "senderName":      senderName,
            "recipientId":     self.chatPartnerId,
            "text":            "",                // no text
            "imageURL":        url.absoluteString,
            "timestamp":       Timestamp()
          ]

          Firestore.firestore()
            .collection("messages")
            .addDocument(data: data) { error in
              if let error = error {
                print("❌ Failed to send image message:", error)
              }
            }
        }
      }
    }
  }


