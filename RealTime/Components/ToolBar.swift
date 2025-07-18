//
//  ToolBar.swift
//  RealTime
//
//  Created by Marcus Grant on 6/19/25.
//

import SwiftUI
import FirebaseFirestore

struct CustomToolbar: ViewModifier {
    var usersViewModel: UsersViewModel

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView(usersViewModel: usersViewModel)) {
                        Image("bell")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .padding(.horizontal)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 100)
                }
            }
    }
}

