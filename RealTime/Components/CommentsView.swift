//
//  CommentsView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/18/25.
//

import SwiftUI

struct CommentsView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)

    let caption: Caption
    @StateObject private var viewModel = CommentsViewModel()
    @EnvironmentObject var usersViewModel: UsersViewModel
    @State private var commentText = ""

    var body: some View {
        VStack {
            // Comment List
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.comments) { comment in
                        let user = usersViewModel.users.first(where: { $0.id == comment.userId })
                        CommentRowView(comment: comment, user: user)
                    }
                }
                .padding()
            }

            // Comment Input
            HStack {
                TextField("", text: $commentText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .placeholder(when: commentText.isEmpty) {
                        Text("Write a comment...")
                            .foregroundColor(.gray)
                            .padding(.leading, 12) // fixes left alignment
                    }



                Button("Send") {
                    guard let user = usersViewModel.currentUser else { return }
                    viewModel.postComment(
                        captionId: caption.id ?? "",
                        text: commentText,
                        userId: user.id,
                        userName: user.name,
                        profileImageURL: user.imageUrl
                    )
                    commentText = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .disabled(commentText.isEmpty)
            }
            .padding(.horizontal)

        }
        .background(customColor.ignoresSafeArea())
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchComments(for: caption.id ?? "")
            usersViewModel.fetchAllUsers()
        }
    }
}





struct CommentRowView: View {
    let comment: Comment
    let user: User?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let user = user {
                NavigationLink(destination: PublicProfileView(user: user)) {
                    if let imageUrl = user.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(comment.userName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(comment.text)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}









