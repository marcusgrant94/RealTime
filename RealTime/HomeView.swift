//
//  ProfileView.swift
//  RealTime
//
//  Created by Marcus Grant on 3/1/24.
//

import SwiftUI
import Firebase

struct HomeView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @State private var post = ""
    @State private var showingImagePicker = false
    @State private var postedCaptions: [String] = []
    @State private var isLoadingImage = false
    @State private var isUserDataLoaded = false
    @EnvironmentObject var storiesViewModel: StoriesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @StateObject var captionsViewModel = CaptionsViewModel()
    @State private var presentingStoryDetail = false
    @State private var profileImage: UIImage?
    @State private var inputImage: UIImage?
    @State private var selectedStory: Story?
    @State private var selectedUserStories: [Story]?
    @State private var isStoryLoading = false
    @State private var showBlockAlert = false
    @State private var captionImage: UIImage? = nil
    @State private var uploadedImageUrl: String? = nil

    
    
    struct PlaceholderTextField: View {
        var placeholder: String
        @Binding var text: String
        var placeholderColor: Color = .gray
        var textColor: Color = .white

        var body: some View {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(placeholderColor)
                        .padding(.leading, 8)
                }
                TextField("", text: $text)
                    .foregroundColor(textColor)
                    .padding(8)
            }
        }
    }

    
    
    private var profileImageView: some View {
        Group {
            if isLoadingImage {
                ActivityIndicatorView(isAnimating: $isLoadingImage, style: .large)
                    .frame(width: 50, height: 50) // Further reduced size
                    .background(Color.clear)
            } else if let profileImage = self.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill) // Fill the frame while maintaining aspect ratio
                    .frame(width: 50, height: 50) // Further reduced size
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Adjusted corner radius for smaller size
            } else {
                ProfilePlaceholder()
                    .frame(width: 50, height: 50) // Further reduced size
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Adjusted corner radius for smaller size
            }
        }
    }
        



    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        
                        Spacer()
                    }
                    HStack {
                        Text("\(self.partOfDay()) \(usersViewModel.currentUser?.name ?? "")")
                        
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                            .frame(height: 100)
                        Spacer()
                        
                    }
                    HStack {
                        Text("\(self.shareYourTime())")
                            .fontWeight(.thin)
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                            .offset(y: -40)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 12) {
                                            profileImageView
                                                .padding(.leading, 10)
                                            HStack(spacing: 8) {
                                                ZStack(alignment: .topLeading) {
                                                    RoundedRectangle(cornerRadius: 13)
                                                        .stroke(Color.gray, lineWidth: 1)
                                                        .background(Color.clear)

                                                    VStack(alignment: .leading, spacing: 6) {
                                                        PlaceholderTextField(placeholder: "Post a caption", text: $post)
                                                            .foregroundColor(.white)
                                                            .fontWeight(.regular)

                                                        if let image = captionImage {
                                                            ZStack(alignment: .topTrailing) {
                                                                Image(uiImage: image)
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(maxHeight: 120)
                                                                    .cornerRadius(8)

                                                                Button {
                                                                    // Remove the selected image
                                                                    captionImage = nil
                                                                } label: {
                                                                    Image(systemName: "xmark.circle.fill")
                                                                        .font(.headline)
                                                                        .foregroundColor(.white)
                                                                        .background(Color.black.opacity(0.6))
                                                                        .clipShape(Circle())
                                                                }
                                                                // Tweak the offset so it sits neatly at the corner
                                                                .offset(x: 6, y: -6)
                                                            }
                                                        }
                                                    }
                                                    .padding(8)
                                                }
                                                .frame(width: 210, height: captionImage == nil ? 50 : 200)

                                                
                                                Button {
                                                    guard let user = usersViewModel.currentUser else { return }
                                                    if let image = captionImage {
                                                        usersViewModel.uploadCaptionImage(image) { url in
                                                            let imageUrl = url?.absoluteString ?? ""
                                                            postCaption(user: user, imageUrl: imageUrl)
                                                            post = ""
                                                            captionImage = nil
                                                        }
                                                    } else {
                                                        postCaption(user: user, imageUrl: nil)
                                                        post = ""
                                                        captionImage = nil
                                                    }
                                                    // dismiss keyboard
                                                    UIApplication.shared.sendAction(
                                                      #selector(UIResponder.resignFirstResponder),
                                                      to: nil, from: nil, for: nil
                                                    )
                                                } label: {
                                                    Image(systemName: "paperplane.fill")
                                                        .font(.title2)
                                                        .foregroundColor(.white)
                                                        .padding(8)
                                                        .opacity((post.isEmpty && captionImage == nil) ? 0.5 : 1)
                                                    }
                                                    .disabled(post.isEmpty && captionImage == nil)
                                                .foregroundColor((post.isEmpty && captionImage == nil) ? .gray : .white)
                                                
                                                Button {
                                                    showingImagePicker = true
                                                } label: {
                                                    Image(systemName: "photo.badge.plus")
                                                        .font(.title2)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                    .sheet(isPresented: $showingImagePicker, onDismiss: loadCaptionImage) {
                        ImagePicker(image: $captionImage)
                    }
                                    .padding(.bottom, 10) // Increased padding to space it from the picker

                                    // Stories Section (no offset)
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            // Use a regular HStack instead of LazyHStack
                            HStack(spacing: 15) {
                                ForEach(usersViewModel.friends, id: \.id) { friend in
                                    if let stories = storiesViewModel.stories[friend.id], !stories.isEmpty {
                                        Button {
                                            isStoryLoading = true
                                            preloadStoryImages(for: stories) { readyStories in
                                                selectedUserStories = readyStories
                                                presentingStoryDetail = true
                                                addViewersToStories(stories: readyStories)
                                                isStoryLoading = false
                                            }
                                        } label: {
                                            StoryThumbnailView(friend: friend, stories: stories)
                                                .opacity(isStoryLoading ? 0.5 : 1)
                                        }
                                    }
                                }
                            }
                                            .padding(.horizontal)
                                        }
                                        .edgesIgnoringSafeArea(.horizontal)
                                    }
                                    // Remaining modifiers for stories section remain unchanged
                                    .refreshable {
                                        refreshStories()
                                    }
                                    .modifier(CustomToolbar(usersViewModel: usersViewModel))
                                    .background(customColor.edgesIgnoringSafeArea(.all))
                                    .sheet(isPresented: $presentingStoryDetail) {
                                        if let stories = selectedUserStories {
                                            StoriesCarouselView(stories: stories)
                                        }
                                    }
                                    .background(customColor.edgesIgnoringSafeArea(.all))
                    
                    CustomSegmentedPicker()
                        .padding()

                                    Spacer()
                                    ForEach(usersViewModel.friends, id: \.id) { friend in
                                        if let storylines = storiesViewModel.storylines[friend.id], !storylines.isEmpty {
                                            VStack(alignment: .leading, spacing: 10) {
                                                Text(friend.name)
                                                    .font(.headline)
                                                    .padding(.leading)
                                                ForEach(storylines, id: \.id) { storyline in
                                                    StorylineCardView(storyline: storyline)
                                                        .padding(.horizontal)
                                                        .environmentObject(usersViewModel)
                                                }
                                            }
                                        }
                                    }
                                    Captions(captionsViewModel: captionsViewModel)
                                }
                            }
                            .background(customColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 22/255.0, green: 29/255.0, blue: 35/255.0, alpha: 1) // Match your customColor
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            usersViewModel.fetchCurrentUser()
                usersViewModel.fetchFriendsForCurrentUser() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let friendIds = usersViewModel.friends.map { $0.id }
                        storiesViewModel.fetchStoriesForUsers(userIds: friendIds)
                        if let user = usersViewModel.currentUser {
                               captionsViewModel.fetchCaptions(for: user.id, friends: user.friends ?? [])
                           }
                        storiesViewModel.fetchStorylinesForFriends(friends: usersViewModel.friends)
                        loadImageFromURL()
                        isUserDataLoaded = true
                    }
                }
            }
        .refreshable {
            // Only include the actions that should happen when the user manually refreshes
            let friendIds = usersViewModel.friends.map { $0.id }
            storiesViewModel.fetchStoriesForUsers(userIds: friendIds)
            storiesViewModel.fetchStorylinesForFriends(friends: usersViewModel.friends)
        }


    }
    
    
    
    
//    private func postCaption() {
//        if !post.isEmpty {
//            postedCaptions.append(post)
//            post = ""
//        }
//    }
    
    
    
    
    private func profileImageView2(url: String?) -> some View {
            Group {
                if let profileImageUrl = url, !profileImageUrl.isEmpty {
                    AsyncImageView3(url: profileImageUrl)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            }
        }
    private func addViewersToStories(stories: [Story]) {
        if let currentUser = usersViewModel.currentUser {
            let viewer = Viewer(id: currentUser.id, name: currentUser.name, profileImageUrl: currentUser.imageUrl)
            for story in stories {
                storiesViewModel.addViewerToStory(storyId: story.id, viewer: viewer)
            }
        }
    }
    
    private func getUserName(userId: String) -> String {
            usersViewModel.friends.first { $0.id == userId }?.name ?? "Unknown"
        }
    
    private func refreshStories() {
        usersViewModel.fetchFriendsForCurrentUser { // Removed [weak self] here
            // If you need to access properties or methods of the view struct, just use them directly.
            // For SwiftUI views, there's typically no risk of a retain cycle in this context.
            
            let friendIds = self.usersViewModel.friends.map { $0.id }
            self.storiesViewModel.fetchStoriesForUsers(userIds: friendIds)
        }
    }
    
    func loadImageFromURL() {
        guard let user = usersViewModel.currentUser,
              let urlString = user.imageUrl,
              let url = URL(string: urlString) else {
            print("URL formation failed")
            return
        }
        
        isLoadingImage = true
        print("Loading image from URL: \(urlString)")

        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                    self.isLoadingImage = false
                    print("Image successfully loaded")
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingImage = false
                    print("Failed to load image from URL")
                }
            }
        }
    }

    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        self.profileImage = inputImage // Sets the chosen image so the UI can update immediately.
        
        if let user = usersViewModel.currentUser {
            // Upload the image for the current user.
            usersViewModel.uploadImage(inputImage, for: user)
            
            // Optional: If you want to refresh user data after image upload, consider doing it in the completion handler of uploadImage.
            // But make sure 'uploadImage' has a completion block if you want to use this.
            // Otherwise, you can call fetchCurrentUser directly like this, but it will not guarantee that it runs after the upload is complete.
            usersViewModel.fetchCurrentUser() // Refresh user data.
        } else {
            print("No current user found for image upload")
        }
    }

    
    func partOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())

        // Convert time to a format that's easier to compare
        let currentTime = hour * 60 + minute // Convert hours to minutes

        // Define time ranges
        let morningEnd = 11 * 60 + 30  // 11:30 AM
        let afternoonEnd = 13 * 60     // 1:00 PM
        let eveningEnd = 23 * 60 + 30  // 11:30 PM

        // Determine part of the day
        if currentTime <= morningEnd {
            return "Good morning"
        } else if currentTime <= afternoonEnd {
            return "Good afternoon"
        } else if currentTime <= eveningEnd {
            return "Good evening"
        } else {
            return "Good night"
        }
    }
    
    func shareYourTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Determine the time of day based on the hour
        if hour >= 7 && hour < 17 { // From 7:00 AM to 4:59 PM
            return "Share your day with us!"
        } else { // From 5:00 PM to 6:59 AM
            return "Share your night with us!"
        }
    }


    func preloadStoryImages(for stories: [Story], completion: @escaping ([Story]) -> Void) {
        let validStories = stories.filter { !$0.imageUrl.isEmpty }
        
        // If all stories already have image URLs
        if validStories.count == stories.count {
            completion(stories)
            return
        }

        // Otherwise: poll until all stories have images (or timeout)
        DispatchQueue.global().async {
            var retries = 0
            while retries < 10 {
                let allReady = stories.allSatisfy { !$0.imageUrl.isEmpty }
                if allReady {
                    DispatchQueue.main.async {
                        completion(stories)
                    }
                    return
                }
                retries += 1
                Thread.sleep(forTimeInterval: 0.2) // wait a bit
            }

            // If timeout, still pass back whatever is there
            DispatchQueue.main.async {
                completion(stories)
            }
        }
    }
    
    func loadCaptionImage() {
        guard let input = inputImage else { return }
        self.captionImage = input
    }

    func postCaption(user: User, imageUrl: String?) {
        captionsViewModel.postCaption(
            text: post,
            userId: user.id,
            userName: user.name,
            profileImageURL: user.imageUrl,
            captionImageURL: imageUrl // Add this to your model
        )
    }


    
}
