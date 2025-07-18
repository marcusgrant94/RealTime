//
//  RecentMessageRow.swift
//  RealTime
//
//  Created by Marcus Grant on 7/2/25.
//

import SwiftUI
import Firebase

struct RecentMessageRow: View {
  let message: Message
  @EnvironmentObject var usersVM: UsersViewModel

  // hold onto the loaded user
  @State private var otherUser: User?

  var body: some View {
    HStack(spacing: 12) {
      avatar
        .frame(width: 50, height: 50)
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(otherUser?.name ?? "…")
          .font(.headline)
          .foregroundColor(.white)

        Text(message.text)
          .font(.subheadline)
          .foregroundColor(.gray)
          .lineLimit(1)
      }

      Spacer()

      Text(shortTime)
        .font(.caption)
        .foregroundColor(.gray)
    }
    .padding(.vertical, 8)
    .padding(.horizontal)
    .background(Color.white.opacity(0.05))
    .cornerRadius(10)
    .onAppear(perform: loadOtherUser)
  }

  private var otherId: String {
    let me = Auth.auth().currentUser?.uid ?? ""
    return (message.senderId == me) ? message.recipientId : message.senderId
  }

  private var avatar: some View {
    if let url = otherUser?.imageUrl, let u = URL(string: url) {
      return AnyView(
        AsyncImage(url: u) { img in img.resizable() }
          placeholder: { Color.gray }
      )
    } else {
      return AnyView(
        Image(systemName: "person.crop.circle.fill")
          .resizable()
          .foregroundColor(.gray)
      )
    }
  }

  private var shortTime: String {
    let date = message.timestamp.dateValue()
    let f = DateFormatter(); f.timeStyle = .short
    return f.string(from: date)
  }

  private func loadOtherUser() {
    // If already loaded via usersVM, use that
    if let u = usersVM.users.first(where: { $0.id == otherId }) {
      otherUser = u
    } else {
      // Otherwise fetch just this one doc
      Firestore.firestore()
        .collection("users")
        .document(otherId)
        .getDocument { snap, _ in
          guard let data = snap?.data() else { return }
          let u = User(
            id: otherId,
            email: data["email"] as? String ?? "",
            name: data["name"]  as? String ?? "No Name",
            imageUrl: data["imageUrl"] as? String,
            bannerImageUrl: data["bannerImageUrl"] as? String,
            friends: data["friends"] as? [String] ?? [],
            bio: data["bio"] as? String
          )
          DispatchQueue.main.async { otherUser = u }
        }
    }
  }
}

