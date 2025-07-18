//
//  AddFriendsView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/14/24.
//

import SwiftUI
import FirebaseFirestore


struct AddFriendsView: View {
    // Your brand color
    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

    @State private var searchText     = ""
    @State private var searchResults  = [User]()
    @State private var addedFriendIds = Set<String>()
    
    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var navigationState: NavigationState
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            // ① Dark background
            customColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ② Dark-themed search bar
                SearchBar(text: $searchText, onSearchButtonClicked: search)
                    .padding(.horizontal)

                // ③ Results list
                List {
                    // Section A: Email search
                    if !searchResults.isEmpty {
                        Section(header:
                                    Text("Search Results")
                            .foregroundColor(.white)
                            .font(.headline)
                        ) {
                            ForEach(searchResults) { user in
                                // Wrap each row in a NavigationLink
                                NavigationLink(destination: PublicProfileView(user: user)) {
                                    FriendRow(
                                        user: user,
                                        addedFriendIds: $addedFriendIds,
                                        usersViewModel: usersViewModel,
                                        db: db
                                    )
                                }
                                .listRowBackground(customColor)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 16) {
                    ForEach(navigationState.matchedUsers) { user in
                      SuggestedFriendsCard(user: user)
                        .environmentObject(usersViewModel)
                    }
                  }
                  .padding(.horizontal)
                }
            }
        }
        .navigationBarTitle("Add Friends", displayMode: .inline)
        .onAppear {
            usersViewModel.fetchAllUsers()
        }
    }

    private func search() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        searchResults = usersViewModel.users.filter {
            $0.email.lowercased().contains(query)
        }
    }
}


// MARK: – Extracted Row View for reuse –
struct FriendRow: View {
    let user: User
    @Binding var addedFriendIds: Set<String>
    var usersViewModel: UsersViewModel
    var db: Firestore

    var body: some View {
        HStack {
            UserCardView(user: user)
            
            Spacer()

            if addedFriendIds.contains(user.id) {
                Text("Friend Added!")
                    .foregroundColor(.green)
            } else {
                Button("Add") {
                    guard let currentUser = usersViewModel.currentUser else { return }

                    // 1) Add to the Firestore array
                    usersViewModel.addFriend(
                        toUserID: currentUser.id,
                        friendID: user.id
                    )
                    addedFriendIds.insert(user.id)

                    // 2) Send push notification entry
                    let notificationData: [String:Any] = [
                        "type": "friend_request",
                        "userId": user.id,
                        "fromUserId": currentUser.id,
                        "captionId": "",
                        "timestamp": Timestamp(date: Date())
                    ]
                    db.collection("notifications").addDocument(
                        data: notificationData
                    ) { error in
                        if let error = error {
                            print("❌ Notification error:", error)
                        }
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}


#Preview {
    AddFriendsView()
        .environmentObject(UsersViewModel())
        .environmentObject(NavigationState())
}
