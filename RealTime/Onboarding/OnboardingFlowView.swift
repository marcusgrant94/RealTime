//
//  OnboardingFlowView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/30/25.
//
import SwiftUI
import Firebase

struct OnboardingFlowView: View {
    @State private var step = 1
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var usersVM: UsersViewModel
    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
        switch step {
        case 1:
            // STEP 1: Name
            SetNameView { name in
                guard let uid = Auth.auth().currentUser?.uid else { return }
                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(["name": name], merge: true)
                usersVM.fetchCurrentUser()
                step = 2
            }
            .environmentObject(usersVM)

        case 2:
            // STEP 2: Profile Picture
            SetProfilePicView(onSave: {
                step = 3
            })
            .environmentObject(usersVM)

        case 3:
            // STEP 3: Bio / Intro (Final Step)
            SetIntroView(onSave: {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(["onboardingCompleted": true], merge: true) { error in
                        if let error = error {
                            print("❌ Error updating onboarding status: \(error.localizedDescription)")
                        } else {
                            DispatchQueue.main.async {
                                authVM.onboardingCompleted = true
                            }
                            print("✅ Onboarding completed and saved to Firestore.")
                        }
                    }
            })
            .environmentObject(usersVM)
            .environmentObject(authVM)

        default:
            EmptyView()
        }
    }
}



