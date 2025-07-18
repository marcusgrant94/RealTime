//
//  ChatView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/18/24.
//

import SwiftUI
import Firebase


struct ChatView: View {
    // ① Your brand color
    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

    @StateObject var messagesViewModel: MessagesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel

    @State private var messageText: String = ""
    let friend: User

    init(friend: User) {
        self.friend = friend
        let me = Auth.auth().currentUser?.uid ?? ""
        _messagesViewModel = StateObject(
            wrappedValue: MessagesViewModel(
                currentUserId: me,
                chatPartnerId: friend.id
            )
        )
    }

    var body: some View {
        ZStack {
            // Brand color behind everything
            customColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // — Messages Scroll —
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messagesViewModel.messages) { message in
                                MessageView(
                                    message: message,
                                    currentUserId: messagesViewModel.currentUserId
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(customColor)
                    .onChange(of: messagesViewModel.messages.count) { _ in
                        if let last = messagesViewModel.messages.last {
                            withAnimation(.easeOut) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()
                    .background(Color.gray)

                // — Your existing MessageInputView —
                MessageInputView(
                                   messageText: $messageText,
                                   sendTextMessage: { text in
                                     messagesViewModel.sendMessage(
                                       text,
                                       senderName: usersViewModel.currentUser?.name ?? ""
                                     )
                                   },
                                   sendImage: { image in
                                     messagesViewModel.sendImage(
                                       image,
                                       senderName: usersViewModel.currentUser?.name ?? ""
                                     )
                                   }
                                )
                            }
                        }
        .toolbar {
                    ToolbarItem(placement: .principal) {
                        NavigationLink(destination: PublicProfileView(user: friend)
                                        .environmentObject(usersViewModel)
                        ) {
                            Text(friend.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    usersViewModel.fetchCurrentUser()
                }
            }
        }






//#Preview {
//    ChatView()
//}
