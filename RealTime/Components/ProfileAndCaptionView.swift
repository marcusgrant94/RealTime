//
//  ProfileAndCaptionView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/10/25.
//

import SwiftUI

struct ProfileAndCaptionView: View {
    @State private var post: String = "" // Use @State for mutable text input
    
    private var profileImageView: some View {
        Image(systemName: "person.circle") // Example placeholder
            .resizable()
            .frame(width: 40, height: 40)
    }
    
    private var postButton: some View {
        Button(action: {
            // Handle posting logic here
            print("Posted: \(post)")
            post = "" // Clear the text field after posting
        }) {
            Text("Post")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
    
    var body: some View {
        HStack {
            profileImageView
                .padding(.horizontal)
                .padding(.vertical)
                .offset(y: -40)
            
            PlaceholderTextField(placeholder: "Post a caption", text: $post)
                .foregroundColor(.white)
                .fontWeight(.regular)
                .padding()
                .frame(width: 216)
                .offset(y: -39)
            
            postButton
                .offset(x: 20, y: -38)
                .disabled(post.isEmpty)
            
            Spacer()
        }
    }
}


struct PlaceholderTextField: View {
    var placeholder: String
    @Binding var text: String
    var placeholderColor: Color = .gray
    var textColor: Color = .white

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(placeholderColor)
                    .padding(.leading, 8)
            }
            TextField("", text: $text)
                .foregroundColor(textColor)
                .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}
