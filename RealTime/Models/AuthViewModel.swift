//
//  AuthViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 12/22/23.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import Firebase
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool? = nil
    @Published var isAuthenticated = false
    var usersViewModel: UsersViewModel?
    @Published var onboardingCompleted: Bool = false
    @Published var didCheckOnboarding: Bool     = false


    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
          guard let self = self else { return }

          // reset the “checked” flag on every sign-in/sign-out
          DispatchQueue.main.async {
            self.didCheckOnboarding = false
          }

          if let uid = user?.uid {
            let docRef = Firestore.firestore().collection("users").document(uid)
            docRef.getDocument { snapshot, _ in
              let data = snapshot?.data() ?? [:]
              let done: Bool

              if snapshot?.exists == false {
                // brand-new user → must complete onboarding
                done = false
                docRef.setData(["onboardingCompleted": false], merge: true)
              }
              else if data["onboardingCompleted"] == nil {
                // legacy user w/o a flag → treat as completed
                done = true
              }
              else {
                done = data["onboardingCompleted"] as? Bool ?? false
              }

              DispatchQueue.main.async {
                self.onboardingCompleted = done
                self.isSignedIn          = true
                self.didCheckOnboarding  = true
              }
            }
          } else {
            // signed out
            DispatchQueue.main.async {
              self.isSignedIn         = false
              self.onboardingCompleted = false
              self.didCheckOnboarding  = true
            }
          }
        }

        NotificationCenter.default.addObserver(
          forName: .init("FCMToken"),
          object: nil,
          queue: .main
        ) { [weak self] note in
          if let token = note.userInfo?["token"] as? String {
            self?.updateFCMToken(token: token)
          }
        }
      }

      deinit {
        if let h = authListener {
          Auth.auth().removeStateDidChangeListener(h)
        }
        NotificationCenter.default.removeObserver(self)
      }
    
    var currentUserId: String? {
           return Auth.auth().currentUser?.uid
       }

    func signIn(email: String,
                    password: String,
                    completion: @escaping (Bool, String?) -> Void)
        {
            Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
                if let error = error {
                    completion(false, error.localizedDescription); return
                }
                if methods?.contains("google.com") == true {
                    completion(false,
                        "This email uses Google login. Please sign in with Google."
                    ); return
                }
                Auth.auth().signIn(withEmail: email, password: password) { result, error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        // refresh token for this user
                        self.refreshFCMTokenForCurrentUser()
                        completion(true, nil)
                    }
                }
            }
        }
    
    
    func handleSignOut() {
            guard let oldUid = Auth.auth().currentUser?.uid else { return }

            // 1) delete old token from Firestore
            Firestore.firestore()
                .collection("users").document(oldUid)
                .updateData(["fcmToken": FieldValue.delete()]) { [weak self] _ in

                    // 2) then actually sign out
                    do {
                        try Auth.auth().signOut()
                        GIDSignIn.sharedInstance.signOut()
                        DispatchQueue.main.async {
                            self?.isSignedIn         = false
                            self?.onboardingCompleted = false
                            self?.usersViewModel?.currentUser = nil
                        }
                        print("✅ Signed out and cleared old FCM token.")
                    } catch {
                        print("❌ Error signing out:", error)
                    }
                }
        }
    
    
    
    func updateFCMToken(token: String) {
        guard let userId = currentUserId else {
            print("User not signed in, can't update FCM token.")
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("Error updating FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token updated successfully.")
            }
        }
    }
    
    
    private func refreshFCMTokenForCurrentUser() {
           guard let uid = Auth.auth().currentUser?.uid else { return }
           Messaging.messaging().token { token, error in
               if let token = token {
                   Firestore.firestore()
                       .collection("users").document(uid)
                       .updateData(["fcmToken": token]) { err in
                           if let err = err {
                               print("❌ Failed to update FCM token:", err)
                           } else {
                               print("✅ Refreshed FCM token for user", uid)
                           }
                       }
               }
           }
       }


    
    func signInWithGoogle(presentingViewController: UIViewController) {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController
            ) { [unowned self] result, error in
                if let error = error {
                    print("❌ Google sign-in error:", error)
                    showAlert(presentingViewController, title: "Sign In Failed",
                              message: "Could not sign in. Please try again.")
                    return
                }
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString
                else {
                    showAlert(presentingViewController, title: "Sign In Failed",
                              message: "Missing Google credentials.")
                    return
                }

                let credential = GoogleAuthProvider
                    .credential(withIDToken: idToken,
                                accessToken: user.accessToken.tokenString)

                Auth.auth().signIn(with: credential) { _, error in
                    if let error = error {
                        print("❌ Firebase Google sign-in error:", error)
                        self.showAlert(presentingViewController, title: "Sign In Failed",
                                  message: "Could not sign in. Try again.")
                        return
                    }
                    DispatchQueue.main.async { self.isSignedIn = true }
                    // refresh token for this user
                    self.refreshFCMTokenForCurrentUser()
                }
            }
        }

    
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.delete { error in
            if let error = error {
                print("Failed to delete account: \(error.localizedDescription)")
                // Optionally show a user-facing error alert
            } else {
                print("Account successfully deleted")
                // Log out or navigate to onboarding screen
            }
        }
    }

    
    


    func showAlert(_ viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func signUpWithGoogle(presentingViewController: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Missing client ID")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [unowned self] result, error in
            if let error = error {
                print("Sign-up failed with error: \(error.localizedDescription)")
                showAlert(presentingViewController, title: "Sign Up Failed", message: "Could not sign up. Please try again.")
                return
            }

            guard let user = result?.user,
                  let email = user.profile?.email,
                  let idToken = user.idToken?.tokenString
            else {
                print("Error: Missing user or token")
                showAlert(presentingViewController, title: "Sign Up Failed", message: "Could not sign up. Please try again.")
                return
            }

            Auth.auth().fetchSignInMethods(forEmail: email) { signInMethods, error in
                if let error = error {
                    print("Fetch sign-in methods error: \(error.localizedDescription)")
                    self.showAlert(presentingViewController, title: "Sign Up Failed", message: "Could not sign up. Please try again.")
                    return
                }

                if signInMethods?.isEmpty ?? true {
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                    Auth.auth().signIn(with: credential) { authResult, error in
                        if let error = error {
                            print("Account creation failed: \(error.localizedDescription)")
                            self.showAlert(presentingViewController, title: "Sign Up Failed", message: "Could not create account. Please try again.")
                            return
                        }
                        print("Account created successfully for \(email) with provider google.com")
                        // Optionally verify immediately
                        Auth.auth().fetchSignInMethods(forEmail: email) { methods, _ in
                            print("Post-sign-up methods: \(methods ?? [])")
                        }
                    }
                } else {
                    print("Existing methods found: \(signInMethods ?? [])")
                    self.showAlert(presentingViewController, title: "Sign Up Failed", message: "An account with this email already exists. Please sign in instead.")
                }
            }
        }
    }
    
    func sendVerificationText(phoneNumberWithCode: String, completion: @escaping (Bool, String?) -> Void) {
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumberWithCode, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    print("❌ Error verifying phone number: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                    return
                }
                
                if let verificationID = verificationID {
                    UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                    print("✅ Verification ID saved: \(verificationID)")
                    completion(true, nil)
                }
            }
    }
    
    func verifyCodeAndStoreUser(verificationCode: String, completion: @escaping (Bool, String?) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            completion(false, "No verification ID found.")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ Error verifying code:", error.localizedDescription)
                completion(false, error.localizedDescription)
                return
            }
            guard let user = result?.user else {
                completion(false, "No user found.")
                return
            }

            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)

            userRef.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    // Existing user: read onboardingCompleted from Firestore
                    print("✅ User already exists in Firestore.")
                    let data = snapshot.data() ?? [:]
                    let onboardingDone: Bool
                    if data["onboardingCompleted"] == nil {
                        // Legacy user without the field, assume onboarding is completed
                        onboardingDone = true
                    } else {
                        onboardingDone = data["onboardingCompleted"] as? Bool ?? false
                    }
                    DispatchQueue.main.async {
                        self.onboardingCompleted = onboardingDone
                        self.isSignedIn = true
                        self.didCheckOnboarding = true
                    }
                    completion(true, nil)
                } else {
                    // New user: create document with onboardingCompleted = false
                    userRef.setData([
                        "id": user.uid,
                        "phoneNumber": user.phoneNumber ?? "",
                        "createdAt": FieldValue.serverTimestamp(),
                        "role": "user",
                        "onboardingCompleted": false
                    ]) { error in
                        if let error = error {
                            print("❌ Error saving new phone user:", error)
                            completion(false, error.localizedDescription)
                        } else {
                            print("✅ New phone user saved; onboarding pending.")
                            DispatchQueue.main.async {
                                self.onboardingCompleted = false
                                self.isSignedIn = true
                                self.didCheckOnboarding = true
                            }
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
}
