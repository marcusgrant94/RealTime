//
//  CameraView.swift
//  RealTime
//
//  Created by Marcus Grant on 11/21/23.
//

import SwiftUI
import AVFoundation
import AVKit
import Firebase

struct CameraView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var navigationState: NavigationState
    @StateObject private var viewModel = CameraViewModel()
    var profileImageURL: String?
    @State private var showCapturedPhoto = false
    @State private var inputImage: UIImage?
    @State private var showCapturedStories = false
    @State private var profileImage: UIImage?
    @State private var isLoadingImage = false
    @State private var isCapturing = false
    @State private var isUserDataLoaded = false
    @State private var capturedPhoto: UIImage?
    @State private var showUploadButton = false
    @State private var showFriendsList = false
    @State private var showEditButton = false
    @State private var previewID = UUID()


    var body: some View {
        ZStack {
            CameraPreview(viewModel: viewModel)
                .background(Color(red: 22/255, green: 29/255, blue: 35/255))
                .edgesIgnoringSafeArea(.all)
                .blur(radius: isCapturing ? 10 : 0)
            
            VStack {
                HStack {
                    Spacer()
                    cameraSwitchButton
                }
                .padding(.top, 44)
                .padding(.trailing, 20)
                
                Spacer()
            }
            
            if let capturedPhoto = capturedPhoto {
                Image(uiImage: capturedPhoto)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.capturedPhoto = nil
                        self.showCapturedPhoto = false
                        self.viewModel.showUploadButton = false
                        self.navigationState.isTabBarHidden = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.viewModel.restartSession()
                        }
                    }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                    }
                    .offset(x: -75, y: -55)
                    .padding()
                }
                
                if viewModel.showUploadButton {
                    VStack {
                        Spacer()
                        HStack {
                            uploadButton
                            sendToButton
                            cancelButton
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            } else {
                cameraUI
            }
        }
        .overlay(
            Group {
                if viewModel.showToast {
                    Text("Sent!")
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .zIndex(1)
                    
                }
            }
            .animation(.easeInOut, value: viewModel.showToast)
            .padding(.bottom, 100),
            alignment: .bottom
        )
        .onAppear {
            viewModel.onPhotoSent = {
                self.capturedPhoto = nil
                self.showCapturedPhoto = false
                self.viewModel.showUploadButton = false
                self.navigationState.isTabBarHidden = false
                previewID = UUID()

            }
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 22/255.0, green: 29/255.0, blue: 35/255.0, alpha: 1)
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
            tabBarAppearance.backgroundColor = UIColor(red: 22/255.0, green: 29/255.0, blue: 35/255.0, alpha: 0.8)
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            usersViewModel.fetchCurrentUser()
            loadImageFromURL()
            navigationState.isTabBarHidden = false
            viewModel.restartSession()
        }
        .onChange(of: showFriendsList) { newValue in
            if newValue {
                viewModel.stopAndResetSession()
            } else {
                capturedPhoto = nil
                showUploadButton = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.viewModel.restartSession()
                }
            }
        }
        .onChange(of: usersViewModel.currentUser) { _ in
            if usersViewModel.currentUser != nil {
                isUserDataLoaded = true
            }
        }
        .onChange(of: isUserDataLoaded) { isLoaded in
            if isLoaded {
                loadImageFromURL()
            }
        }
        .onDisappear {
            navigationState.isTabBarHidden = false
        }
    }
    
    private var cameraSwitchButton: some View {
        Button {
            viewModel.switchCamera()
        } label: {
            Image(systemName: "camera.rotate")
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.black.opacity(0.7)))
        }
    }
    
    private var sendToButton: some View {
        Button("Send to") {
            showFriendsList = true
        }
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .sheet(isPresented: $showFriendsList) {
            FriendsListView(
                capturedPhoto: capturedPhoto,
                usersViewModel: usersViewModel,
                cameraViewModel: viewModel,
                isPresented: $showFriendsList
            )
        }
    }

    private var cameraUI: some View {
        VStack {
            HStack {
                Button(action: {
                    showCapturedStories.toggle()
                }) {
                    profileImageView
                }
                .offset(x: -150, y: 40)
                .padding(.top)
                .sheet(isPresented: $showCapturedStories) {
                    CapturedStoriesView()
                }
            }
            Spacer()
            Button(action: capturePhoto) {
                Image(systemName: "camera")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.7)))
            }
            .offset(y: -10)
            .padding(.bottom, 105)
        }
    }

    private var uploadButton: some View {
        Button("Upload to Stories") {
            guard let userID = authViewModel.currentUserId else { return }

            // 1️⃣ Immediately tear down the running session
            viewModel.stopAndResetSession()

            // 2️⃣ Kick off your upload
            viewModel.uploadPhotoToStories(userID: userID) {
                // 3️⃣ And as soon as it’s done, restart the live preview
                DispatchQueue.main.async {
                    viewModel.restartSession()
                }
            }
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }


    private var cancelButton: some View {
        Button("Cancel") {
            self.capturedPhoto = nil
            viewModel.showUploadButton = false
            navigationState.isTabBarHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewModel.restartSession()
            }
        }
        .padding()
    }

    private func capturePhoto() {
        isCapturing = true
        viewModel.capturePhoto()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let capturedImage = viewModel.capturedImage {
                self.showCapturedPhoto = true
                self.capturedPhoto = capturedImage
                viewModel.showUploadButton = true
                self.showEditButton = true
                navigationState.isTabBarHidden = true
            }
            isCapturing = false
        }
    }

    var profileImageView: some View {
        Group {
            if isLoadingImage {
                ActivityIndicatorView(isAnimating: $isLoadingImage, style: .large)
                    .frame(width: 50, height: 50)
            } else if let uiImage = self.profileImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                ProfilePlaceholder()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
        }
        .onAppear {
            loadImageFromURL()
        }
    }
    
    private func loadImageFromURL() {
        guard let urlString = usersViewModel.currentUser?.imageUrl,
              let url = URL(string: urlString) else {
            return
        }
        isLoadingImage = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingImage = false
                if let data = data, let image = UIImage(data: data) {
                    self.profileImage = image
                }
            }
        }.resume()
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        self.profileImage = inputImage
        if let user = usersViewModel.currentUser {
            usersViewModel.uploadImage(inputImage, for: user)
            usersViewModel.fetchCurrentUser()
        }
    }
}

struct CapturedImageView: View {
    @Binding var capturedImage: UIImage?
    var onDismiss: () -> Void
    var onSave: (UIImage) -> Void
    @EnvironmentObject var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .offset(y: 40)
                                .font(.largeTitle)
                                .padding()
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { onSave(image) }) {
                            Image(systemName: "square.and.arrow.down")
                                .offset(y: 40)
                                .font(.largeTitle)
                                .padding()
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
            }
        }
        .alert(isPresented: $viewModel.showSaveAlert) {
            Alert(
                title: Text("Saved"),
                message: Text("Your image has been saved to the photo library."),
                dismissButton: .default(Text("OK")) {
                    viewModel.showSaveAlert = false
                }
            )
        }
    }
}
