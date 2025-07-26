//
//  Captions.swift
//  RealTime
//
//  Created by Marcus Grant on 6/19/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore


struct Captions: View {
    @ObservedObject var captionsViewModel: CaptionsViewModel

    var body: some View {
        ZStack {
            // Always fill with your theme color
            Color(red: 22/255, green: 29/255, blue: 35/255)
                .ignoresSafeArea()

            if captionsViewModel.captions.isEmpty {
                // Placeholder when there are no captions
                VStack(spacing: 20) {
                    Spacer()

                    // Illustration from your Assets catalog (add the PNG as "EmptyCaptionsIllustration")
                    Image("emptycaptions")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .opacity(0.6)

                    Text("Its quiet here\nadd friends or post a caption to get started")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
            } else {
                // Your existing list of captions
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Captions")
                            .foregroundColor(.white)
                            .font(.title2)
                            .bold()
                            .padding(.leading)

                        ForEach(captionsViewModel.captions) { caption in
                            CaptionCard(
                                caption: caption,
                                captionsViewModel: captionsViewModel
                            )
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .animation(.easeInOut, value: captionsViewModel.captions.isEmpty)
    }
}




import SwiftUI
import FirebaseAuth

// Define an Identifiable struct to hold the image URL
struct FullImage: Identifiable {
    let id = UUID()
    let url: URL
}

struct CaptionCard: View {
    var caption: Caption
    var captionsViewModel: CaptionsViewModel
    @State private var fullImage: FullImage?
    @State private var showingFlagDialog = false
    @State private var flagReason: String? = nil
    @State private var showingOtherReasonSheet = false
    @State private var otherReasonText = ""
    @State private var showingReportConfirmation = false


    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Username and timestamp and delete button
            HStack {
                Text(caption.userName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formattedDate(caption.timestamp.dateValue()))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if caption.userId == Auth.auth().currentUser?.uid {
                    Button {
                        captionsViewModel.deleteCaption(caption)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Caption text
            if !caption.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(caption.text)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.25))
                    .cornerRadius(12)
            }
            
            // Image (tappable)
            if let urlString = caption.captionImageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 300)
                            .clipped()
                            .cornerRadius(12)
                            .contentShape(Rectangle()) // ensures only the image responds to taps
                            .onTapGesture {
                                fullImage = FullImage(url: url)
                            }
                    case .failure(_):
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            
            // Likes & Comments
            HStack(spacing: 16) {
                // ❤️ Like toggle
                Image(systemName: caption.liked ? "heart.fill" : "heart")
                    .foregroundColor(caption.liked ? .red : .white)
                    .onTapGesture {
                        captionsViewModel.toggleLike(caption: caption)
                    }
                
                // Like count (if >0)
                if caption.likeCount > 0 {
                    NavigationLink(destination: WhoLikedView(likedBy: caption.likedBy)) {
                        Text("\(caption.likeCount) Like\(caption.likeCount != 1 ? "s" : "")")
                            .foregroundColor(.white)
                    }
                }
                
                // 💬 Comments
                NavigationLink(destination: CommentsView(caption: caption)) {
                    Image(systemName: "text.bubble.fill")
                        .foregroundColor(.white)
                    Text("\(caption.commentCount ?? 0)")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 🚩 Flag button
                Button {
                                   showingFlagDialog = true
                               } label: {
                                   Image(systemName: "flag")
                                       .foregroundColor(.white)
                               }
                               .frame(maxWidth: .infinity, alignment: .trailing)

                           }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .sheet(item: $fullImage) { item in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                AsyncImage(url: item.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
                    case .failure(_):
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }

                Button(action: {
                    fullImage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .padding()
                }
            }
        }
        .confirmationDialog("Report this post", isPresented: $showingFlagDialog, titleVisibility: .visible) {
            Button("Spam") { flagReason = "Spam" }
            Button("Harassment") { flagReason = "Harassment" }
            Button("Hate Speech") { flagReason = "Hate Speech" }
            Button("Other…") {
                showingOtherReasonSheet = true
            }
            Button("Cancel", role: .cancel) { }
        }
        // 3️⃣ Present a little TextField sheet when “Other…” is tapped:
        .sheet(isPresented: $showingOtherReasonSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Why are you reporting this?")
                        .font(.headline)
                        .padding(.top)

                    TextField("Enter reason…", text: $otherReasonText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Spacer()

                    Button("Submit Report") {
                        // use their custom text as the reason
                        flagReason = otherReasonText.isEmpty ? "Other" : otherReasonText
                        otherReasonText = ""
                        showingOtherReasonSheet = false
                    }
                    .disabled(otherReasonText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding()
                }
                .navigationBarTitle("Report Post", displayMode: .inline)
                .navigationBarItems(trailing: Button("Cancel") {
                    otherReasonText = ""
                    showingOtherReasonSheet = false
                })
            }
        }
               // when a reason is chosen, fire off the report
               .onChange(of: flagReason) { reason in
                   guard let reason = reason else { return }
                   captionsViewModel.flagCaption(caption, reason: reason)
                   showingReportConfirmation = true
                   // reset
                   flagReason = nil
               }
               .alert("Report Sent",
                      isPresented: $showingReportConfirmation,
                      actions: {
                          Button("OK", role: .cancel) { }
                      },
                      message: {
                          Text("Thank you for helping us keep the community safe.")
                      }
               )

           }

    func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // Options: .abbreviated, .short, .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


struct PublicCaptionCard: View {
    var caption: Caption
    @State private var fullImage: FullImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Username and timestamp
            HStack {
                Text(caption.userName)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(formattedDate(caption.timestamp.dateValue()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Caption text
            if !caption.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(caption.text)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.25))
                    .cornerRadius(12)
            }

            // Caption image
            if let urlString = caption.captionImageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        ZStack {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 300)
                                .clipped()
                                .cornerRadius(12)

                            // Invisible tappable overlay only covering the image
                            Rectangle()
                                .foregroundColor(.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    fullImage = FullImage(url: url)
                                }
                        }
                    case .failure(_):
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Likes and comments
            HStack {
                if caption.likeCount > 0 {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(caption.likeCount) Like\(caption.likeCount != 1 ? "s" : "")")
                        .foregroundColor(.white)
                }

                if let commentCount = caption.commentCount, commentCount > 0 {
                    Image(systemName: "text.bubble.fill")
                        .foregroundColor(.white)
                    Text("\(commentCount)")
                        .foregroundColor(.white)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .sheet(item: $fullImage) { item in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                AsyncImage(url: item.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding()
                    case .failure(_):
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }

                Button(action: {
                    fullImage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .padding()
                }
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // Options: .abbreviated, .short, .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}







