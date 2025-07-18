//
//  NotificationsView.swift
//  RealTime
//
//  Created by Marcus Grant on 7/27/24.
//

import SwiftUI

struct NotificationsView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    @StateObject private var notificationsViewModel: NotificationsViewModel
    @ObservedObject private var usersViewModel: UsersViewModel
    
    init(usersViewModel: UsersViewModel) {
        _notificationsViewModel = StateObject(wrappedValue: NotificationsViewModel(usersViewModel: usersViewModel))
        self.usersViewModel = usersViewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                customColor.edgesIgnoringSafeArea(.all)
                List {
                    ForEach(notificationsViewModel.notifications) { notification in
                        HStack(spacing: 12) {
                            if let user = usersViewModel.users.first(where: { $0.id == notification.fromUserId }) {
                                if let imageUrl = user.imageUrl, let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 45, height: 45)
                                        .clipShape(Circle())
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(notification.type == "friend_request" ?
                                         "\(user.name) added you as a friend" :
                                            "\(user.name) liked your caption")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    Text("\(notification.timestamp.dateValue(), formatter: dateFormatter)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text("Someone liked your caption")
                                        .font(.headline)
                                    Text("\(notification.timestamp.dateValue(), formatter: dateFormatter)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(customColor.edgesIgnoringSafeArea(.all))
                        .listRowBackground(customColor)
                    }
                    .onDelete(perform: delete)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Notifications")
                .onAppear {
                    usersViewModel.fetchAllUsers() // Ensure users are fetched first
                    notificationsViewModel.fetchNotifications()
                }
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let notification = notificationsViewModel.notifications[index]
            notificationsViewModel.deleteNotificationById(notificationId: notification.id)
        }
    }
}



private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

