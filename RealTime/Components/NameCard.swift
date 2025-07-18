//
//  NameCard.swift
//  RealTime
//
//  Created by Marcus Grant on 6/16/25.
//

import SwiftUI

struct NameCard: View {
    let usersViewModel: UsersViewModel
    @State private var isEditingName = false
    @State private var nameText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .foregroundColor(.gray)
                        .font(.subheadline)

                    if isEditingName {
                        TextField("Enter your name", text: $nameText)
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.words)
                    } else {
                        Text(usersViewModel.currentUser?.name ?? "")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }

                Spacer()

                Button(isEditingName ? "Save" : "Edit") {
                    if isEditingName {
                        if let userID = usersViewModel.currentUser?.id {
                            usersViewModel.updateName(userId: userID, newName: nameText)
                        }
                    } else {
                        nameText = usersViewModel.currentUser?.name ?? ""
                    }

                    isEditingName.toggle()
                }
                .foregroundColor(.purple)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
            .onChange(of: usersViewModel.currentUser?.name) { newName in
                nameText = newName ?? ""
            }
        }
    }
}

