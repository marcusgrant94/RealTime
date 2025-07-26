//
//  UsersViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 1/5/24.
//

import Foundation
import Firebase
import FirebaseStorage

struct User: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let email: String
    let name: String
    var imageUrl: String?  // Instead of profileImageURL
    var bannerImageUrl: String?
    let friends: [String]
    var blockedUsers: [String]? = []
    var bio: String?
    
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }

}


class UsersViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var currentUser: User?
    @Published var friends = [User]()
    @Published var isLoadingFriends = false
    
    
    private var db = Firestore.firestore()
    
    
    func fetchCurrentUser() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let userRef = db.collection("users").document(userID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let id = document.documentID
                let email = data?["email"] as? String ?? ""
                let name = data?["name"] as? String ?? ""
                let imageUrl = data?["imageUrl"] as? String
                let bannerImageURL = data?["bannerImageUrl"] as? String  // Added this line
                let friends = data?["friends"] as? [String] ?? []
                let bio = data?["bio"] as? String ?? ""

                DispatchQueue.main.async {
                    // Ensure your User model has a bannerImageURL parameter in its initializer
                    self.currentUser = User(id: id, email: email, name: name, imageUrl: imageUrl, bannerImageUrl: bannerImageURL, friends: friends, bio: bio)
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func fetchAllUsers() {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                self.users = querySnapshot?.documents.compactMap { document -> User? in
                    let data = document.data()
                    let id = document.documentID
                    let email = data["email"] as? String ?? ""
                    let name = data["name"] as? String ?? ""
                    let imageUrl = data["imageUrl"] as? String
                    let bannerImageURL = data["bannerImageUrl"] as? String
                    let friends = data["friends"] as? [String] ?? []
                    let bio = data["bio"] as? String ?? ""


                    return User(id: id, email: email, name: name, imageUrl: imageUrl, bannerImageUrl: bannerImageURL, friends: friends, bio: bio)
                } ?? []
            }
        }
    }
    
    func fetchFriendsForCurrentUser(completion: @escaping () -> Void = {}) {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                completion()
                return
            }

            isLoadingFriends = true
            let userRef = db.collection("users").document(currentUserID)
            userRef.getDocument { [weak self] document, error in
                guard let self = self else { return }

                // If there's no friends array, bail out
                guard let doc = document,
                      doc.exists,
                      let data = doc.data(),
                      let friendIDs = data["friends"] as? [String],
                      !friendIDs.isEmpty
                else {
                    DispatchQueue.main.async {
                        self.friends = []
                        self.isLoadingFriends = false
                        completion()
                    }
                    return
                }

                // Use a DispatchGroup to wait for all lookups
                let group = DispatchGroup()
                var loadedFriends: [User] = []

                for friendID in friendIDs {
                    group.enter()
                    self.db.collection("users").document(friendID).getDocument { snap, _ in
                        defer { group.leave() }
                        guard let snap = snap, snap.exists, let fd = snap.data() else { return }
                        let friend = User(
                            id: snap.documentID,
                            email: fd["email"] as? String ?? "",
                            name: fd["name"] as? String ?? "",
                            imageUrl: fd["imageUrl"] as? String,
                            bannerImageUrl: fd["bannerImageUrl"] as? String,
                            friends: [],           // not needed here
                            bio: fd["bio"] as? String ?? ""
                        )
                        loadedFriends.append(friend)
                    }
                }

                // Once *all* lookups finish, update on the main thread
                group.notify(queue: .main) {
                    self.friends = loadedFriends
                    self.isLoadingFriends = false
                    completion()
                }
            }
        }
    
    func deleteFriend(_ friend: User) {
           guard let currentUserID = Auth.auth().currentUser?.uid else { return }

           let userRef = db.collection("users").document(currentUserID)
           userRef.updateData([
               "friends": FieldValue.arrayRemove([friend.id])
           ]) { error in
               if let error = error {
                   print("Error removing friend: \(error.localizedDescription)")
               } else {
                   print("Friend removed successfully.")
                   DispatchQueue.main.async {
                       self.friends.removeAll { $0.id == friend.id }
                   }
               }
           }
       }





    
    
    func addFriend(toUserID userID: String, friendID: String) {
            let userRef = db.collection("users").document(userID)

            userRef.updateData([
                "friends": FieldValue.arrayUnion([friendID])
            ]) { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    print("Error adding friend: \(error.localizedDescription)")
                    return
                }

                print("Friend added successfully on server.")

                // 1) Immediately update our local array
                DispatchQueue.main.async {
                    // Find the User object in our cached `users`
                    if let newFriend = self.users.first(where: { $0.id == friendID }),
                       !self.friends.contains(newFriend) {
                        self.friends.append(newFriend)
                    }
                }

                // 2) Send the notification document
                guard let senderId = self.currentUser?.id else { return }
                let notificationData: [String: Any] = [
                    "type": "friend_request",
                    "userId": friendID,
                    "fromUserId": senderId,
                    "captionId": "",
                    "timestamp": Timestamp()
                ]
                self.db.collection("notifications").addDocument(data: notificationData) { error in
                    if let error = error {
                        print("Failed to send friend request notification: \(error)")
                    } else {
                        print("Friend request notification sent")
                    }
                }
            }
        }




    
//    func updateUserProfile(userID: String, age: Int, heightFeet: Int, heightInches: Int, weight: Int, completion: @escaping (Error?) -> Void) {
//        let userRef = db.collection("users").document(userID)
//        userRef.updateData([
//            "age": age,
//            "height": [
//                "feet": heightFeet,
//                "inches": heightInches
//            ],
//            "weight": weight
//        ]) { error in
//            if let error = error {
//                print("Failed to update user profile: \(error)")
//                completion(error)
//            } else {
//                print("User profile successfully updated!")
//                completion(nil)
//            }
//        }
//    }
//    
    func uploadImage(_ image: UIImage, for user: User, completion: ((URL?) -> Void)? = nil) {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            print("❌ Failed to convert image to JPEG")
            completion?(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("images/\(user.id).jpg")

        storageRef.putData(data, metadata: nil) { [weak self] (_, error) in
            if let error = error {
                print("❌ Error uploading image: \(error)")
                completion?(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Error getting download URL: \(error)")
                    completion?(nil)
                    return
                }

                guard let url = url else {
                    completion?(nil)
                    return
                }

                // Update Firestore with new image URL
                let db = Firestore.firestore()
                db.collection("users").document(user.id).setData([
                    "imageUrl": url.absoluteString
                ], merge: true) { error in
                    if let error = error {
                        print("❌ Error saving image URL to Firestore: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            if let currentUser = self?.currentUser, currentUser.id == user.id {
                                self?.currentUser = User(id: currentUser.id, email: currentUser.email, name: currentUser.name, imageUrl: url.absoluteString, bannerImageUrl: currentUser.bannerImageUrl, friends: currentUser.friends)
                            }
                            if let index = self?.users.firstIndex(where: { $0.id == user.id }) {
                                self?.users[index] = User(id: user.id, email: user.email, name: user.name, imageUrl: url.absoluteString, bannerImageUrl: user.bannerImageUrl, friends: user.friends)
                            }
                        }
                    }
                    // Always call completion at the end
                    completion?(url)
                }
            }
        }
    }
    
    func uploadCaptionImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            print("Failed to compress image")
            completion(nil)
            return
        }

        let filename = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("captionImages/\(filename)")

        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error)")
                    completion(nil)
                    return
                }
                completion(url)
            }
        }
    }


        
    
    func uploadBannerImage(_ image: UIImage, for user: User, in viewModel: UsersViewModel) {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            // Handle error: Failed to get JPEG representation of UIImage
            return
        }
        
        let storageRef = Storage.storage().reference().child("bannerImages/\(user.id).jpg")
        
        storageRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                // Handle error: Error occurred during upload
                print("Error uploading banner image: \(error)")
                return
            }
            
            storageRef.downloadURL { [weak self] (url, error) in
                if let error = error {
                    // Handle error: Couldn't retrieve download URL
                    print("Error getting banner download URL: \(error)")
                    return
                }
                
                if let url = url {
                    // Update the user document in Firestore with the banner image URL
                    let db = Firestore.firestore()
                    db.collection("users").document(user.id).setData([
                        "bannerImageUrl": url.absoluteString
                    ], merge: true) { error in
                        if let error = error {
                            // Handle error: Failed to update user document
                            print("Error saving banner image URL to Firestore: \(error)")
                        } else {
                            // Successfully updated user document with banner image URL
                            DispatchQueue.main.async {
                                // Update currentUser with the new banner image URL
                                if let currentUser = self?.currentUser {
                                    self?.currentUser = User(id: currentUser.id, email: currentUser.email, name: currentUser.name, imageUrl: currentUser.imageUrl, bannerImageUrl: url.absoluteString, friends: currentUser.friends)
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Flags a user by adding a report to Firestore
       func flagUser(_ userId: String, reason: String) {
           guard let reporter = Auth.auth().currentUser?.uid else {
               print("⚠️ No reporter ID available")
               return
           }
           let report: [String: Any] = [
               "reportedUserId": userId,
               "reporterId": reporter,
               "reason": reason,
               "timestamp": Timestamp()
           ]
           db.collection("userReports").addDocument(data: report) { error in
               if let error = error {
                   print("❌ Failed to report user: \(error)")
               } else {
                   print("✅ Reported user \(userId) for \(reason)")
               }
           }
       }
    
    func updateBio(userId: String, newBio: String) {
        let userRef = db.collection("users").document(userId)
        userRef.updateData(["bio": newBio]) { error in
            if let error = error {
                print("Error updateing bio: \(error.localizedDescription)")
            } else {
                print("Bio Successfully Updated.")
                self.fetchCurrentUser()
            }
        }
    }
    
    func updateName(userId: String, newName: String) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).updateData([
            "name": newName
        ]) { error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
            } else {
                print("Name successfully updated.")
                self.fetchCurrentUser() // Refresh locally
            }
        }
    }
    
    func deleteAccountAndData(completion: @escaping (Result<Void, Error>) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "No user ID", code: 0)))
                return
            }

            let db = Firestore.firestore()

            // Step 1: Fetch all captions posted by the user
            db.collection("captions").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let batch = db.batch()

                // Delete each caption
                snapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }

                // Step 2: Delete user document
                let userRef = db.collection("users").document(userId)
                batch.deleteDocument(userRef)

                // Commit all deletions
                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    // Step 3: Delete the Firebase Auth user
                    Auth.auth().currentUser?.delete { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            DispatchQueue.main.async {
                                self.currentUser = nil
                            }
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    
    func fetchMatchedContacts(completion: @escaping ()->Void = {}) {
      guard let uid = Auth.auth().currentUser?.uid else { return }
      let contactCol = Firestore.firestore()
        .collection("users")
        .document(uid)
        .collection("syncedContacts")

      contactCol.getDocuments { snap, _ in
        let phones = snap?.documents
          .compactMap { $0.data()["phoneNumbers"] as? [String] }
          .flatMap { $0 } ?? []

        guard !phones.isEmpty else {
          completion()
          return
        }

        // query the users collection for documents whose "phoneNumber" is in that list
        Firestore.firestore()
          .collection("users")
          .whereField("phoneNumber", in: phones)
          .getDocuments { userSnap, _ in
            let found = userSnap?.documents.compactMap { doc -> User? in
              try? doc.data(as: User.self)
            } ?? []
            DispatchQueue.main.async {
              // store them in navigationState
              // you might inject NavigationState into this VM or return found
              completion()
            }
          }
      }
    }



    
//    func blockUser(blockedUserId: String) {
//            guard let currentUserID = Auth.auth().currentUser?.uid else { return }
//            let userRef = db.collection("users").document(currentUserID)
//            
//            userRef.updateData([
//                "blockedUsers": FieldValue.arrayUnion([blockedUserId])
//            ]) { error in
//                if let error = error {
//                    print("Error blocking user: \(error.localizedDescription)")
//                } else {
//                    print("User blocked successfully.")
//                    DispatchQueue.main.async {
//                        self.currentUser?.blockedUsers?.append(blockedUserId)
//                    }
//                }
//            }
//        }
//    
//    func unblockUser(blockedUserId: String) {
//            guard let currentUserID = Auth.auth().currentUser?.uid else { return }
//            let userRef = db.collection("users").document(currentUserID)
//            
//            userRef.updateData([
//                "blockedUsers": FieldValue.arrayRemove([blockedUserId])
//            ]) { error in
//                if let error = error {
//                    print("Error unblocking user: \(error.localizedDescription)")
//                } else {
//                    print("User unblocked successfully.")
//                    DispatchQueue.main.async {
//                        self.currentUser?.blockedUsers?.removeAll { $0 == blockedUserId }
//                    }
//                }
//            }
//        }
}
