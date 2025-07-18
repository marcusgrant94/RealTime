//
//  PostButton.swift
//  RealTime
//
//  Created by Marcus Grant on 6/10/25.
//

import SwiftUI


struct PostButton: View {
    @EnvironmentObject var usersViewModel: UsersViewModel
    @StateObject var captionsViewModel = CaptionsViewModel()
    @State var post: String = ""
    
    var body: some View {
        Button("Post") {
            if let userId = usersViewModel.currentUser?.id, let userName = usersViewModel.currentUser?.name, let profileImageURL = usersViewModel.currentUser?.imageUrl {
                captionsViewModel.postCaption(text: post, userId: userId, userName: userName, profileImageURL: profileImageURL)
                post = ""
            }
        }
    }
}

