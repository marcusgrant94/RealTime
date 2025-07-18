//
//  MessageView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/18/24.
//

import SwiftUI

struct MessageView: View {
    var message: Message
    @State private var isImageViewerPresented: Bool = false
    var currentUserId: String

    var body: some View {
        HStack {
            // Align to the right if the message is from the current user
            if message.senderId == currentUserId {
                Spacer()
            }

            // Message content
            if let imageURL = message.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 150, height: 150)
                .cornerRadius(10)
                .onTapGesture {
                    isImageViewerPresented = true
                }
                .sheet(isPresented: $isImageViewerPresented) {
                    FullScreenImageView(imageURL: url)
                }
            } else {
                Text(message.text)
                    .padding()
                    .background(ChatBubble(isFromCurrentUser: message.senderId == currentUserId)
                        .fill(message.senderId == currentUserId ? Color.blue : Color.gray.opacity(0.45)))
                    .foregroundColor(message.senderId == currentUserId ? .white : .white)
            }

            // Align to the left if the message is not from the current user
            if message.senderId != currentUserId {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct ChatBubble: Shape {
    var isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, isFromCurrentUser ? .bottomLeft : .bottomRight], cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}

struct FullScreenImageView: View {
    var imageURL: URL

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image.resizable()
                 .aspectRatio(contentMode: .fit)
        } placeholder: {
            ProgressView()
        }
        .edgesIgnoringSafeArea(.all)
    }
}


