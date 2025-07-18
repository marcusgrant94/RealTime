//
//  FriendsView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/14/24.
//

import SwiftUI

struct FriendsView: View {
    let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)
    @EnvironmentObject var usersViewModel: UsersViewModel

    init() {
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().separatorStyle = .none

        let navBar = UINavigationBarAppearance()
        navBar.configureWithOpaqueBackground()
        navBar.backgroundColor = UIColor(red: 22/255, green: 29/255, blue: 35/255, alpha: 1)
        navBar.titleTextAttributes      = [.foregroundColor: UIColor.white]
        navBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance   = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Full‑screen background
                customColor.ignoresSafeArea()

                if usersViewModel.isLoadingFriends {
                                   ProgressView()
                                       .progressViewStyle(CircularProgressViewStyle(tint: .white))

                               // 2) empty state, *only* after load completes
                               } else if usersViewModel.friends.isEmpty {
                    // — Empty state —
                    VStack(spacing: 24) {
                        Spacer()

                        Image("EmptyFriendsIllustration")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .opacity(0.6)

                        Text("You haven’t added any friends yet.\nTap below to find and add friends!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        NavigationLink(destination: AddFriendsView()) {
                            Text("Find Friends")
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }

                        Spacer()
                    }
                    .animation(.easeInOut, value: usersViewModel.friends.isEmpty)

                } else {
                    // — Normal friends list —
                    List {
                        ForEach(usersViewModel.friends, id: \.id) { friend in
                            HStack {
                                if let url = friend.imageUrl, !url.isEmpty {
                                    AsyncImageView(url: url)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                }

                                Text(friend.name)
                                    .foregroundColor(.white)
                                    .font(.headline)

                                Spacer()

                                NavigationLink(destination: PublicProfileView(user: friend)) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                }
                            }
                            .listRowBackground(customColor)
                        }
                        .onDelete(perform: deleteFriend)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable { refreshFriendsList() }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddFriendsView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            usersViewModel.fetchFriendsForCurrentUser() { }
        }
    }
    
    private func deleteFriend(at offsets: IndexSet) {
            offsets.forEach { index in
                let friend = usersViewModel.friends[index]
                usersViewModel.deleteFriend(friend)
            }
        }
    
    private func refreshFriendsList() {
        usersViewModel.fetchFriendsForCurrentUser() {
            // Actions to perform after friends are fetched, if any.
        }
    }
}

