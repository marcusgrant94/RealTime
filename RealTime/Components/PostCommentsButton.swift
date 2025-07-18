//
//  PostCommentsButton.swift
//  RealTime
//
//  Created by Marcus Grant on 6/20/25.
//

import SwiftUI

struct PostCommentsButton: View {
    @ObservedObject var viewModel: CommentsViewModel
    @ObservedObject var captionsViewModel: CaptionsViewModel
    @ObservedObject var usersViewModel: UsersViewModel
    @State private var commentText = ""
    let caption: Caption


    var body: some View {
        HStack {
            TextField("Write a comment...", text: $commentText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)

            Button("Send") {
                guard let user = usersViewModel.currentUser else { return }

                viewModel.postComment(
                    captionId: caption.id ?? "",
                    text: commentText,
                    userId: user.id,
                    userName: user.name,
                    profileImageURL: user.imageUrl // ✅ Use imageUrl from User model
                )
                commentText = ""
            }
            .disabled(commentText.isEmpty)
        }
    }
}
