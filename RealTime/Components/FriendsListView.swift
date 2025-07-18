//
//  FriendsListView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/23/24.
//

import SwiftUI

struct FriendsListView: View {
    var capturedPhoto: UIImage?
    @ObservedObject var usersViewModel: UsersViewModel
    var cameraViewModel: CameraViewModel
    @Binding var isPresented: Bool
    @State private var selectedFriends = Set<String>()
    var onPhotoSent: (() -> Void)?
    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

    init(capturedPhoto: UIImage?, usersViewModel: UsersViewModel, cameraViewModel: CameraViewModel, isPresented: Binding<Bool>, onPhotoSent: (() -> Void)? = nil) {
        self.capturedPhoto = capturedPhoto
        self.usersViewModel = usersViewModel
        self.cameraViewModel = cameraViewModel
        self._isPresented = isPresented
        self.onPhotoSent = onPhotoSent
        
        // Set navigation bar appearance globally
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 22/255, green: 29/255, blue: 35/255, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // Ensure title is white
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }


    var body: some View {
            ZStack {
                // ② Brand‐color background behind everything
                customColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ③ Push list into a NavigationView so we can style its bar
                    NavigationView {
                        List(usersViewModel.friends, id: \.id) { friend in
                            SelectableFriendRow(friend: friend, selectedFriends: $selectedFriends)
                                .listRowBackground(customColor)  // list row also on brand color
                        }
                        .listStyle(.plain)
                        .toolbar {
                                            // force a white title
                                            ToolbarItem(placement: .principal) {
                                                Text("Send to")
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                            }
                                        }
                        .toolbarBackground(customColor, for: .navigationBar)
                        .toolbarColorScheme(.dark,   for: .navigationBar)
                        .background(customColor)
                    }
                    .navigationViewStyle(StackNavigationViewStyle()) // for iPad/mac

                    // ④ “Send” button sticks to the bottom
                    if !selectedFriends.isEmpty, let photo = capturedPhoto {
                        Button {
                            cameraViewModel.selectedFriendIds = selectedFriends
                            cameraViewModel.sendPhotoToSelectedFriends(photo)
                            cameraViewModel.onPhotoSent = {
                                self.isPresented = false
                            }
                        } label: {
                            Text("Send")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)              // white fill
                                .foregroundColor(customColor)         // brand‐color text
                                .cornerRadius(10)
                                .padding()
                        }
                    }
                }
            }
        }
    }

struct SelectableFriend: View {
    let friend: User
    @Binding var selectedFriends: Set<String>
    
    var body: some View {
        HStack {
            Circle()
                .stroke(selectedFriends.contains(friend.id ?? " ") ? Color.red : Color.gray, lineWidth: 2)
        }
    }
}



struct SelectableFriendRow: View {
    let friend: User
    @Binding var selectedFriends: Set<String>

    var body: some View {
        HStack {
            Circle()
                .stroke(selectedFriends.contains(friend.id ?? " ") ? Color.blue : Color.gray, lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay(
                    selectedFriends.contains(friend.id ?? " ") ? Circle().fill(Color.blue) : nil
                )
                .onTapGesture {
                    if selectedFriends.contains(friend.id ?? " ") {
                        selectedFriends.remove(friend.id ?? " ")
                    } else {
                        selectedFriends.insert(friend.id ?? " ")
                    }
                }

            Text(friend.name)
                .foregroundColor(.white)
        }
    }
}



