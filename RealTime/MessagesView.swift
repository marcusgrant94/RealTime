//
//  MessagesView.swift
//  RealTime
//
//  Created by Marcus Grant on 11/24/23.
//

import SwiftUI
import Firebase

// 1) Update your MessagesView to read from navigationState:
struct MessagesView: View {
    let appearance = UINavigationBarAppearance()

    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

    @StateObject private var vm = RecentMessagesViewModel()
    @EnvironmentObject var usersVM: UsersViewModel
    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
      ZStack {
        customColor.ignoresSafeArea()

        if vm.recentMessages.isEmpty {
          VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Text("No recent messages")
              .font(.title2).bold()
              .foregroundColor(.white)
            Text("Add and message friends to get started")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.7))

            Spacer()
          }

        } else {
          List {
            ForEach(vm.recentMessages) { msg in
              let me      = Auth.auth().currentUser!.uid
              let otherId = msg.senderId == me ? msg.recipientId : msg.senderId

              if let realUser = usersVM.users.first(where: { $0.id == otherId }) {
                NavigationLink {
                  ChatView(friend: realUser)
                    .environmentObject(usersVM)
                } label: {
                  RecentMessageRow(message: msg)
                }
                .listRowBackground(customColor)
                .swipeActions(edge: .trailing) {
                  Button(role: .destructive) {
                    vm.deleteConversation(with: otherId)
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }
                }
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
      }
      .toolbar {
                          // force a white title
                          ToolbarItem(placement: .principal) {
                              Text("Messages")
                                  .foregroundColor(.white)
                                  .font(.headline)
                          }
                      }
      .toolbarBackground(customColor, for: .navigationBar)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          let appearance = UINavigationBarAppearance()
                          appearance.configureWithOpaqueBackground()
                          appearance.backgroundColor = UIColor(red: 22/255, green: 29/255, blue: 35/255, alpha: 1)
                          appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                          appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                          UINavigationBar.appearance().standardAppearance = appearance
                          UINavigationBar.appearance().scrollEdgeAppearance = appearance
                          UINavigationBar.appearance().tintColor = .white
                      }
        usersVM.fetchAllUsers()
        vm.fetch()
      }
    }

    /// Fallback if you ever need to look up the “other” participant
    private func otherUser(for msg: Message) -> User {
        let me = Auth.auth().currentUser?.uid ?? ""
        let otherId = (msg.senderId == me) ? msg.recipientId : msg.senderId
        return usersVM.users.first { $0.id == otherId }
           ?? User(id: otherId, email: "", name: "Unknown", imageUrl: nil, bannerImageUrl: nil, friends: [])
    }
}

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let navigationController = uiViewController.navigationController {
            self.configure(navigationController)
        }
    }
}

