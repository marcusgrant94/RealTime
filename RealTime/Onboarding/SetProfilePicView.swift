//
//  SetProfilePicView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct SetProfilePicView: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    
    /// Parent’s callback to advance to the next step
    let onSave: () -> Void

    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false

    var body: some View {
        let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

        ZStack {
            customColor.ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                HStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                    Spacer()
                    Button("Help") { /* … */ }
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                Spacer()

                // Title
                Text("Add a profile picture")
                    .font(.title2).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Picture picker
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture { showingImagePicker = true }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $selectedImage)
                }

                // Save button
                Button("Save Profile Picture") {
                    uploadProfilePic()
                }
                .disabled(selectedImage == nil)
                .opacity(selectedImage == nil ? 0.5 : 1)
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)

                Spacer()
            }
        }
    }

    private func uploadProfilePic() {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let img = selectedImage,
            let data = img.jpegData(compressionQuality: 0.5)
        else {
            print("❌ Missing user ID or image data")
            return
        }

        let ref = Storage.storage().reference().child("profileImages/\(uid).jpg")
        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                print("❌ Error uploading image:", error)
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    print("❌ Error fetching download URL:", error)
                    return
                }
                guard let url = url else { return }

                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(["imageUrl": url.absoluteString], merge: true) { error in
                        if let error = error {
                            print("❌ Failed to save image URL:", error)
                        } else {
                            usersViewModel.fetchCurrentUser()
                            // 🚀 Advance the parent flow
                            DispatchQueue.main.async {
                                onSave()
                            }
                        }
                    }
            }
        }
    }
}
