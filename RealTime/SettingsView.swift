//
//  SettingsView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/5/24.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct SettingsView: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage? = nil
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @State private var inputImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showingConfirmationAlert = false
    @State var bioText = ""
    @State var showSetBioView = false
    @State private var showingDeleteAlert = false
    @State var isDeleting = false


    var body: some View {
        ZStack {
            customColor
            ScrollView {
                VStack {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            // Profile image
                            if isLoadingImage {
                                ActivityIndicatorView(isAnimating: $isLoadingImage, style: .large)
                                    .frame(width: 150, height: 150)
                            } else if let profileImage = self.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                profilePlaceholder
                                    .frame(width: 100, height: 100)
                            }
                            
                            // Camera icon
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .bold))
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .foregroundColor(.gray)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .offset(x: 4, y: 4)
                        }
                    }
                    .padding()
                    
                    if let currentUser = usersViewModel.currentUser {
                        Text(currentUser.name)
                            .foregroundStyle(.white)
                            .bold()
                            .padding(.top, 8)
                        Text(currentUser.email)
                            .foregroundStyle(.white)
                            .padding(.top, 2)
                    } else {
                        Text("Not Signed In")
                            .foregroundStyle(.white)
                            .bold()
                            .padding(.top, 8)
                    }
                    
                    
                    Group {
                        Text("About Me")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        NameCard(usersViewModel: usersViewModel)
                        HStack {
                            Text("Self-introduction")
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                            Button("Edit") {
                                showSetBioView.toggle()
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.25))
                                .frame(minHeight: 80, maxHeight: 150)
                            
                            if !bioText.isEmpty {
                                Text(bioText)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text("Add a short bio...")
                                    .foregroundColor(.gray)
                                    .italic()
                                    .padding(8)
                            }
                        }
                        
                    }
                    .padding(.top, 10)
                    .sheet(isPresented: $showSetBioView) {
                        NavigationView {
                            SetBioView(usersViewModel: usersViewModel) {
                                showSetBioView = false
                                // No need to assign bioText here if you add onChange
                            }
                        }
                    }
                    .onAppear {
                        bioText = usersViewModel.currentUser?.bio ?? ""
                    }
                    .onChange(of: usersViewModel.currentUser?.bio) { newBio in
                        bioText = newBio ?? ""
                    }
                    
                    
                    
                    
                    
                    Spacer()
                    
                    Button {
                        showingConfirmationAlert = true
                    } label: {
                        Text("Log Out")
                            .foregroundColor(.red)
                    }
                    .offset(y: 25)

                    
                    if isDeleting {
                        ProgressView("Deleting Account...")
                            .padding()
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                    .offset(y: 85)
                    .alert("Are you sure?", isPresented: $showingDeleteAlert) {
                        Button("Delete", role: .destructive) {
                            isDeleting = true
                            authViewModel.deleteAccount()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This action is permanent and cannot be undone.")
                    }

                }
            }
            .padding(.horizontal)
            .background(customColor)
            .alert(isPresented: $showingConfirmationAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out"), action: {
                        authViewModel.handleSignOut()
                    }),
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .onAppear {
                usersViewModel.fetchCurrentUser()
                if let bio  = usersViewModel.currentUser?.bio {
                    self.bioText = bio
                }
                loadImageFromURL()
            }
        }
    }

    var profilePlaceholder: some View {
        ZStack {
            if let initial = usersViewModel.currentUser?.name.first {
                Circle()
                    .fill(generateRandomColor())
                    .frame(width: 100, height: 100)
                Text(String(initial))
                    .foregroundColor(.white)
                    .font(.largeTitle)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 100, height: 100)
            }
        }
    }

    func generateRandomColor() -> Color {
        // Generates a random color
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }

    func loadImageFromURL() {
        guard let user = usersViewModel.currentUser,
              let urlString = user.imageUrl,
              let url = URL(string: urlString) else {
            return
        }
        
        isLoadingImage = true

        DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.profileImage = UIImage(data: data)
                        self.isLoadingImage = false  // Stop loading
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoadingImage = false  // Stop loading
                    }
                }
            }
        }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        self.profileImage = inputImage // Sets the locally chosen image so the UI can update immediately
        
        if let user = usersViewModel.currentUser {
            // Call uploadImage without the 'in' parameter
            usersViewModel.uploadImage(inputImage, for: user)
            
            // After updating the image in storage and Firestore, it's common to re-fetch the current user
            // to ensure all data is up-to-date, but consider if this is necessary or if you can update
            // just the necessary user data locally to avoid an unnecessary network request.
            usersViewModel.fetchCurrentUser() // Consider whether this call is needed based on your app's logic
    }
}
}



//#Preview {
//    SettingsView()
//}
