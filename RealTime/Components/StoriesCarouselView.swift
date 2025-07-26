//
//  StoriesCarouselView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/27/24.
//

import SwiftUI

struct StoriesCarouselView: View {
    var stories: [Story]
    @State private var currentIndex: Int = 0
    @State private var showingFlagDialog = false
        @State private var flagReason: String? = nil
        @State private var showingOtherReasonSheet = false
        @State private var otherReasonText = ""
        @State private var showingReportConfirmation = false
    @EnvironmentObject var storiesViewModel: StoriesViewModel


        var body: some View {
            GeometryReader { geometry in
                if stories.indices.contains(currentIndex) {
                    let story = stories[currentIndex]

                    ZStack(alignment: .topLeading) {
                        // Fullscreen story image
                        AsyncImage(url: URL(string: story.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height)
                                    .ignoresSafeArea()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // 🚩 Flag button top‐leading
                        Button {
                            showingFlagDialog = true
                        } label: {
                            Image(systemName: "flag")
                                .font(.title2)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        .padding(.leading, 16)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Advance
                        if currentIndex < stories.count - 1 {
                            currentIndex += 1
                        } else {
                            currentIndex = 0
                        }
                    }
                    // MARK: — report dialog
                    .confirmationDialog("Report this story", isPresented: $showingFlagDialog, titleVisibility: .visible) {
                        Button("Spam")            { flagReason = "Spam" }
                        Button("Harassment")      { flagReason = "Harassment" }
                        Button("Hate Speech")     { flagReason = "Hate Speech" }
                        Button("Other…")          { showingOtherReasonSheet = true }
                        Button("Cancel", role: .cancel) { }
                    }
                    // MARK: — custom‐reason sheet
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
                                    let reason = otherReasonText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    flagReason = reason.isEmpty ? "Other" : reason
                                    otherReasonText = ""
                                    showingOtherReasonSheet = false
                                }
                                .disabled(otherReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .padding()
                            }
                            .navigationBarTitle("Report Story", displayMode: .inline)
                            .navigationBarItems(trailing: Button("Cancel") {
                                otherReasonText = ""
                                showingOtherReasonSheet = false
                            })
                        }
                    }
                    // MARK: — fire off report & confirm
                    .onChange(of: flagReason) { reason in
                        guard let reason = reason else { return }
                        // your view-model call:
                        storiesViewModel.flagStory(story, reason: reason)
                        showingReportConfirmation = true
                        flagReason = nil
                    }
                    .alert("Report Sent",
                           isPresented: $showingReportConfirmation,
                           actions: {
                             Button("OK", role: .cancel) { }
                           },
                           message: {
                             Text("Thank you for keeping the community safe.")
                           }
                    )
                }
            }
        }
    }
