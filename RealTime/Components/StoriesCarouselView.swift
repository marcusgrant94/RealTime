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

    var body: some View {
        GeometryReader { geometry in
            if stories.indices.contains(currentIndex) {
                let story = stories[currentIndex]
                VStack {
                    AsyncImage(url: URL(string: story.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width)
                                .ignoresSafeArea(.all)
                        case .failure:
                            Image(systemName: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle()) // Make sure the entire area is tappable
                .onTapGesture {
                    // Advance to the next story
                    if currentIndex < stories.count - 1 {
                        currentIndex += 1
                    } else {
                        // Close the view or loop back to the first story
                        currentIndex = 0
                    }
                }
            }
        }
    }
}
