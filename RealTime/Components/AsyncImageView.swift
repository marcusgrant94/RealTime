//
//  AsyncImageView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/16/24.
//

import SwiftUI

struct AsyncImageView: View {
    @State private var image: UIImage?
    @State private var isLoading: Bool = false
    let url: String

    var body: some View {
        Group {
            if isLoading {
                ProgressView() // Shows a loading indicator while the image is loading
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Image(systemName: "photo") // A placeholder image
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear {
            loadImage()
        }
    }

    func loadImage() {
            guard let imageUrl = URL(string: url), image == nil else { return }
        print("Loading image from URL: \(url)")
            isLoading = true
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                        self.isLoading = false
                    }
                } else {
                    print("Unable to load image from data.")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }.resume()
        }
}

struct AsyncImageView2: View {
    @State private var image: UIImage?
    @State private var isLoading: Bool = false
    let url: String

    var body: some View {
        Group {
            if isLoading {
                ProgressView() // Shows a loading indicator while the image is loading
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: 150)
            } else {
                Image(systemName: "photo") // A placeholder image
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width, height: 110)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    func loadImage() {
            guard let imageUrl = URL(string: url), image == nil else { return }
        print("Loading image from URL: \(url)")
            isLoading = true
            URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                        self.isLoading = false
                    }
                } else {
                    print("Unable to load image from data.")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }.resume()
        }
}

struct AsyncImageView3: View {
    @State private var image: UIImage?
    @State private var isLoading: Bool = false
    let url: String

    init(url: String) {
        self.url = url
        print("AsyncImageView3 - Initialized with URL: \(url)")
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill() // better for avatars
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFill()
            }
        }
        .onAppear {
            loadImage()
        }
    }

    func loadImage() {
        guard let imageUrl = URL(string: url), image == nil else {
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}









