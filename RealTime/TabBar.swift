//
//  TabBar.swift
//  RealTime
//
//  Created by Marcus Grant on 11/24/23.
//

import SwiftUI

struct TabBar: View {
    @StateObject private var captionsViewModel = CaptionsViewModel()
    @EnvironmentObject var navigationState: NavigationState
      @EnvironmentObject var usersViewModel: UsersViewModel

    init() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(
            red: 22/255, green: 29/255, blue: 35/255, alpha: 1
        )
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $navigationState.selectedTab) {
                    // Home Tab
                    NavigationStack(path: $navigationState.captionPath) {
                        HomeView()
                            .navigationDestination(for: String.self) { captionId in
                                // Look up the caption in your view model
                                if let cap = captionsViewModel.captions.first(where: { $0.id == captionId }) {
                                    CommentsView(caption: cap)
                                        .environmentObject(usersViewModel)
                                } else {
                                    // Fallback if not found
                                    Text("Caption not found").foregroundColor(.white)
                                }
                            }
                            .onAppear {
                                // If we got a deep‑link for a caption, push it
                                if let cid = navigationState.deepLinkCaptionId {
                                    navigationState.captionPath = [cid]
                                    navigationState.deepLinkCaptionId = nil
                                }
                            }
                    }
            .tabItem { Label("Home",     systemImage: "house") }
            .tag(NavigationState.Tab.home)

            NavigationStack(path: $navigationState.chatPath) {
                MessagesView()
                    .environmentObject(usersViewModel)
                    .environmentObject(navigationState)
                    .navigationDestination(for: String.self) { partnerId in
                                if let friend = usersViewModel.users.first(where: { $0.id == partnerId }) {
                                    ChatView(friend: friend)
                                } else {
                                    Text("User not found")
                                        .environmentObject(usersViewModel)
                                }
                            }
            }
          .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }
          .tag(NavigationState.Tab.messages)

          CameraView()
            .tabItem { Label("Camera",    systemImage: "camera") }
            .tag(NavigationState.Tab.camera)

          ProfileView(captionsViewModel: CaptionsViewModel())
            .tabItem { Label("Profile",   systemImage: "person.fill") }
            .tag(NavigationState.Tab.profile)

          FriendsView()
            .tabItem { Label("Friends",   systemImage: "person.3") }
            .tag(NavigationState.Tab.friends)
        }
        .accentColor(Color(white: 0.8))
        .background(Color(red: 22/255, green: 29/255, blue: 35/255))
    }
}



#Preview {
    TabBar()
        .environmentObject(UsersViewModel())
        .environmentObject(NavigationState())
        .environmentObject(CaptionsViewModel())
}
