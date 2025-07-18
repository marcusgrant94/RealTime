//
//  PublicProfileView.swift
//  RealTime
//
//  Created by Marcus Grant on 7/5/24.
//

import SwiftUI


struct PublicProfileView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @State private var isLoadingImage = false
    @EnvironmentObject var usersViewModel: UsersViewModel
    @StateObject var captionsViewModel = CaptionsViewModel()
    @State private var presentingStoryDetail = false
    @State private var showingBannerImagePicker = false
    @State private var profileImage: UIImage?
    @State private var inputImage: UIImage?
    @State private var bannerImage: UIImage? = nil
    @State private var selectedStory: Story?
    @State private var selectedUserStories: [Story]?
    @EnvironmentObject var navigationState: NavigationState
    @State private var bioText: String = ""
    @State var showUnavailableAlert = false

    var user: User
    
    private var isFriend: Bool {
            usersViewModel.friends.contains(where: { $0.id == user.id })
        }

    private var profileImageView: some View {
        Group {
            if let imageUrl = user.imageUrl, !imageUrl.isEmpty {
                AsyncImageView(url: imageUrl)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            } else {
                ProfilePlaceholder()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Banner
                Button(action: {
                    self.showingBannerImagePicker = true
                }) {
                    // Banner and Profile Image stacked together
                    ZStack(alignment: .bottom) {
                        // Banner Image
                        if let bannerImageUrl = user.bannerImageUrl, !bannerImageUrl.isEmpty {
                            AsyncImageView2(url: bannerImageUrl)
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                        } else if let bannerImage = bannerImage {
                            Image(uiImage: bannerImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                        } else {
                            Color.gray.frame(height: 150)
                        }
                        
                        // Profile Image - Floating over banner
                        profileImageView
                            .frame(width: 100, height: 100)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .offset(y: 50) // float it halfway down
                    }
                }

                    // Fix spacing after ZStack
                    Spacer().frame(height: 60) // to push down next section below the floating profile pic


                // Name
                Text(user.name)
                    .foregroundColor(.white)
                    .font(.title2)

                // Message / Block buttons
                if user.id != usersViewModel.currentUser?.id {
                                    HStack(spacing: 20) {
                                        if isFriend {
                                            // If already friends, show Message
                                            NavigationLink {
                                                ChatView(friend: user)
                                                    .onAppear { navigationState.isTabBarHidden = true }
                                                    .onDisappear { navigationState.isTabBarHidden = false }
                                            } label: {
                                                Text("Message")
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 24)
                                                    .padding(.vertical, 12)
                                                    .background(Color.blue)
                                                    .cornerRadius(8)
                                            }
                                        } else {
                                            // Otherwise show Add Friend
                                            Button {
                                                guard let me = usersViewModel.currentUser else { return }
                                                usersViewModel.addFriend(toUserID: me.id, friendID: user.id)
                                            } label: {
                                                Text("Add Friend")
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 24)
                                                    .padding(.vertical, 12)
                                                    .background(Color.green)
                                                    .cornerRadius(8)
                                            }
                                        }

                                        Button {
                                                                    // instead of actual block, show the "not available" alert
                                                                    showUnavailableAlert = true
                                                                } label: {
                                                                    Text("Block")
                                                                        .foregroundColor(.white)
                                                                        .padding()
                                                                        .background(Color.gray.opacity(0.5))
                                                                        .cornerRadius(10)
                                                                }
                                                                .alert("Feature Unavailable",
                                                                       isPresented: $showUnavailableAlert
                                                                ) {
                                                                    Button("OK", role: .cancel) { }
                                                                } message: {
                                                                    Text("This feature isn’t available yet.")
                                                                }
                                                            }
                                                        }

                // Bio
                if !bioText.isEmpty {
                    Text(bioText)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("No Bio Set...")
                        .foregroundColor(.gray)
                        .italic()
                }

                // Captions
                if !captionsViewModel.publicCaptions.isEmpty {
                    ForEach(captionsViewModel.publicCaptions.reversed()) { caption in
                        PublicCaptionCard(caption: caption)
                    }
                } else {
                    Text("No posts yet.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.top) // Push content below nav bar
            .frame(maxWidth: .infinity)
        }
        .background(customColor.ignoresSafeArea())
        .onAppear {
            bioText = user.bio ?? ""
            loadImageFromURL(urlString: user.imageUrl)
            loadBannerImageFromURL(urlString: user.bannerImageUrl)
            captionsViewModel.fetchCaptionsForUserProfile(userId: user.id)
        }
    }



    
    private func getUserName(userId: String) -> String {
            usersViewModel.friends.first { $0.id == userId }?.name ?? "Unknown"
        }
    
    private func loadBannerImageFromURL(urlString: String?) {
            guard let urlString, let url = URL(string: urlString) else { return }
            isLoadingImage = true
            URLSession.shared.dataTask(with: url) { data, _, _ in
                DispatchQueue.main.async { self.isLoadingImage = false }
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.bannerImage = img }
            }.resume()
        }




    
    private func loadImageFromURL(urlString: String?) {
            guard let urlString, let url = URL(string: urlString) else { return }
            isLoadingImage = true
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImage = image
                        self.isLoadingImage = false
                    }
                } else {
                    DispatchQueue.main.async { self.isLoadingImage = false }
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
        } else {
            print("No current user found for image upload")
        }
    }

    
    func loadBannerImage() {
        guard let inputBannerImage = self.inputImage else { return }
        self.bannerImage = inputBannerImage // Update the banner image to the newly selected one
        
        // Ensure we have a current user to upload the image for
        guard let currentUser = usersViewModel.currentUser else {
            print("No current user found for banner upload")
            return
        }
        
        // Call the function to upload the new banner image
        usersViewModel.uploadBannerImage(inputBannerImage, for: currentUser, in: usersViewModel)
        
        // Reset the input image for next use
        self.inputImage = nil
    }


            }

            struct CircleImageView2: View {
                // Custom view for the circular profile image
                var body: some View {
                    Image("profile") // Replace with your profile image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100) // Adjust the size as needed
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4)) // White border
                        .shadow(radius: 10) // Optional: add shadow
                        .padding(.top, 150) // Adjust this padding to move the circle down to overlap the banner image
        }
                
                
                
                
                
    }

