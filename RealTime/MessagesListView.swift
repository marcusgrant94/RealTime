//
//  MessagesListView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/17/24.
//

import SwiftUI
import Firebase


struct MessagesListView: View {
    @ObservedObject var messagesViewModel: MessagesViewModel
    @EnvironmentObject var usersViewModel: UsersViewModel

    // ① Your brand color
    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

    var body: some View {
        ZStack {
            // Dark background behind everything
            customColor
                .ignoresSafeArea()

            // Scroll of recent messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messagesViewModel.messages) { message in
                        // Reuse your row (RecentMessageRow or MessageView, etc.)
                        RecentMessageRow(message: message)
                            .environmentObject(usersViewModel)
                            .background(customColor)
                    }
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            messagesViewModel.fetchMessages()
            usersViewModel.fetchAllUsers()
        }
    }
}





import SwiftUI

struct MessageInputView: View {
    @Binding var messageText: String
    var sendTextMessage: (String) -> Void
    var sendImage: (UIImage) -> Void

    @State private var showingImagePicker = false
    @State private var pickedImage: UIImage?

    private let barColor   = Color(red: 22/255, green: 29/255, blue: 35/255)
    private let fieldColor = Color(red: 44/255, green: 49/255, blue: 54/255)

    var body: some View {
        HStack(spacing: 8) {
            // — Text field with custom placeholder —
            ZStack(alignment: .leading) {
                if messageText.isEmpty {
                    Text("Type a message…")
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                }
                TextField("", text: $messageText)
                    .padding(8)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .disableAutocorrection(true)
            }
            .background(fieldColor)
            .cornerRadius(8)

            // — Send text button —
            Button(action: {
                let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                sendTextMessage(trimmed)
                messageText = ""
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespaces).isEmpty
                        ? .gray : .blue
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)

            // — Photo picker button —
            Button {
                showingImagePicker = true
            } label: {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(barColor)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $pickedImage)
                .onDisappear {
                    if let img = pickedImage {
                        sendImage(img)
                        pickedImage = nil
                    }
                }
        }
    }
}



