//
//  SetBioView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/16/25.


import SwiftUI

struct SetBioView: View {
    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)

    @ObservedObject var usersViewModel: UsersViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var bioText: String = ""
    var onSave: (() -> Void)?
    
    var body: some View {
        ZStack {
            customColor
                .ignoresSafeArea(edges: .all)
            VStack(alignment: .leading) {
                Text("Self-introduction")
                    .font(.headline)
                    .padding(.bottom, 8)
                    .foregroundStyle(.white)
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.25)) // background
                        .frame(height: 150)

                    TextEditor(text: $bioText)
                        .foregroundColor(.white)
                        .frame(height: 150) // ⬅️ matches the RoundedRectangle
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .padding(.horizontal)






                
                Spacer()
                
                Button("Save") {
                    if let userID = usersViewModel.currentUser?.id {
                        usersViewModel.updateBio(userId: userID, newBio: bioText)
                        onSave?()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .onAppear {
                bioText = usersViewModel.currentUser?.bio ?? ""
            }
            .navigationTitle("Edit Bio")
            .foregroundStyle(.white)

        }
    }
}
