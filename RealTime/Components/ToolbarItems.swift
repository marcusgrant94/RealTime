//
//  ToolbarItems.swift
//  RealTime
//
//  Created by Marcus Grant on 6/10/25.
//

import SwiftUI

struct ToolbarModifier: ViewModifier {
    let usersViewModel: UsersViewModel

    func body(content: Content) -> some View {
        content
            .toolbar {
                bellItem
                settingsItem
                logoItem
            }
    }

    // Break into sub-expressions to avoid compiler overload
    private var bellItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: NotificationsView(usersViewModel: usersViewModel)) {
                Image("bell")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .padding(.horizontal)
            }
        }
    }

    private var settingsItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear")
                    .foregroundStyle(.white)
            }
        }
    }

    private var logoItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100)
        }
    }
}

