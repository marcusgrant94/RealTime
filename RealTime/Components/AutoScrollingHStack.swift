//
//  AutoScrollingHStack.swift
//  RealTime
//
//  Created by Marcus Grant on 6/27/25.
//

import SwiftUI

struct AutoScrollingHStack: UIViewRepresentable {
    let images: [String]
    let scrollSpeed: CGFloat // points per second

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = false // We control scrolling programmatically

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Duplicate images for infinite scrolling
        let displayImages = images + images

        // Load images and add to stack view
        for name in displayImages {
            if let image = UIImage(named: name) {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFill
                imageView.layer.cornerRadius = 30
                imageView.clipsToBounds = true
                imageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 60),
                    imageView.heightAnchor.constraint(equalToConstant: 60)
                ])
                stack.addArrangedSubview(imageView)
            }
        }

        scrollView.addSubview(stack)

        // Set up constraints using contentLayoutGuide for horizontal scrolling
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.frameLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.frameLayoutGuide.bottomAnchor)
        ])

        // Set up CADisplayLink for scrolling
        let displayLink = CADisplayLink(target: context.coordinator, selector: #selector(context.coordinator.updateScroll))
        displayLink.add(to: .main, forMode: .default)

        // Store references in coordinator
        context.coordinator.displayLink = displayLink
        context.coordinator.scrollView = scrollView
        context.coordinator.scrollSpeed = scrollSpeed

        // Calculate width of first set for infinite scrolling
        let n = images.count
        let imageWidth: CGFloat = 60
        let spacing: CGFloat = 20
        context.coordinator.widthOfFirstSet = CGFloat(n) * imageWidth + CGFloat(n - 1) * spacing

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var displayLink: CADisplayLink?
        weak var scrollView: UIScrollView?
        var scrollSpeed: CGFloat = 30
        var widthOfFirstSet: CGFloat = 0

        @objc func updateScroll() {
            guard let scrollView = scrollView else { return }
            let currentOffset = scrollView.contentOffset.x
            let offsetX = currentOffset + scrollSpeed / 60.0 // Assuming 60 FPS
            if offsetX >= widthOfFirstSet {
                scrollView.contentOffset.x = offsetX - widthOfFirstSet
            } else {
                scrollView.contentOffset.x = offsetX
            }
        }

        deinit {
            displayLink?.invalidate()
        }
    }
}

