//
//  ContentView.swift
//  RealTime
//
//  Created by Marcus Grant on 11/20/23.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var navigationState: NavigationState

    // ① Your brand color
    private let theme = Color(red: 22/255, green: 29/255, blue: 35/255)

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 22/255, green: 29/255, blue: 35/255, alpha: 1)
        appearance.titleTextAttributes      = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            // Dark theme behind everything
            theme
                .ignoresSafeArea()

            // Actual content on top
            Group {
                // 1️⃣ Loading state
                if authViewModel.isSignedIn == nil || authViewModel.didCheckOnboarding == false {
                    LoadingView()

                // 2️⃣ Signed out → Welcome
                } else if authViewModel.isSignedIn == false {
                    WelcomeView()
                        .environmentObject(authViewModel)

                // 3️⃣ Signed in + checked onboarding
                } else {
                    if authViewModel.onboardingCompleted {
                        TabBar()
                            .environmentObject(navigationState)
                            .environmentObject(authViewModel)
                    } else {
                        NavigationView {
                            OnboardingFlowView()
                        }
                        .environmentObject(authViewModel)
                        .environmentObject(navigationState)
                    }
                }
            }
            // add a little fade when switching
            .animation(.easeInOut(duration: 0.25), value: authViewModel.didCheckOnboarding)
        }
        
    }
}

// A simple branded loader
struct LoadingView: View {
    private let theme = Color(red: 22/255, green: 29/255, blue: 35/255)

    var body: some View {
        ZStack {
            theme
                .ignoresSafeArea()
            Image("logo")       // or whatever your branding image is
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
        }
    }
}






#Preview {
    ContentView().environmentObject(AuthViewModel())
}
