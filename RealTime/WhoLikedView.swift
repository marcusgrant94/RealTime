//
//  WhoLikedView.swift
//  RealTime
//
//  Created by Marcus Grant on 7/14/24.
//

import SwiftUI
import FirebaseFirestore

struct WhoLikedView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)

    var likedBy: [String]
    @State private var users: [User] = []
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            customColor
                .edgesIgnoringSafeArea(.all)

            List {
                ForEach(users) { user in
                    NavigationLink(destination: PublicProfileView(user: user)) {
                        HStack(spacing: 12) {
                            if let imageUrl = user.imageUrl, !imageUrl.isEmpty {
                                AsyncImageView3(url: imageUrl)
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                            }

                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.leading, -5)
                        .padding(.vertical, 5)
                    }
                    .listRowBackground(customColor)
                }
            }
            .listStyle(PlainListStyle())
            .background(customColor)
            .scrollContentBackground(.hidden)
            .onAppear {
                fetchUsers()
                let appearance = UINavigationBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0, alpha: 1)
                    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

                    UINavigationBar.appearance().standardAppearance = appearance
                    UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        // Replace .navigationTitle with custom Text view
        .navigationBarTitle(Text("Likes").foregroundColor(.white), displayMode: .inline)
    }

    func fetchUsers() {
        let group = DispatchGroup()
        var fetchedUsers: [User] = []

        for userId in likedBy {
            group.enter()
            db.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    print("Error fetching document for user \(userId): \(error.localizedDescription)")
                    group.leave()
                    return
                }
                guard let document = document, document.exists else {
                    print("Document for user \(userId) does not exist")
                    group.leave()
                    return
                }
                // Print raw data
                if let data = document.data() {
                    print("Raw document data for \(userId): \(data)")
                } else {
                    print("No data found for user \(userId)")
                }
                // Attempt to decode
                do {
                    let user = try document.data(as: User.self)
                    fetchedUsers.append(user)
                    print("Successfully decoded user: \(user.name)")
                } catch {
                    print("Error decoding user \(userId): \(error.localizedDescription)")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.users = fetchedUsers
            print("Fetched users: \(fetchedUsers.map { $0.name })")
        }
    }
    
    
}






