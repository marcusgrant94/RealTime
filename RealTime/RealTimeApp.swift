//
//  RealTimeApp.swift
//  RealTime
//
//  Created by Marcus Grant on 11/20/23.
//

import SwiftUI
import UIKit
import Firebase
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

class NavigationState: ObservableObject {
    enum Tab: Hashable {
          case home, messages, camera, profile, friends
        }
    @Published var isTabBarHidden: Bool = false
    @Published var showMatchesFound: Bool = false
    @Published var matchedUsers: [User] = []
    @Published var selectedTab: Tab = .home
    @Published var deepLinkChatPartnerId: String?
    @Published var chatPath: [String]         = []
    @Published var deepLinkCaptionId: String?
       @Published var captionPath: [String] = []
}



@main
struct RealTimeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var authViewModel = AuthViewModel()
    @StateObject var usersViewModel = UsersViewModel()
    @StateObject var navigationState = NavigationState()
    @StateObject private var storiesViewModel = StoriesViewModel()
    
//    init() {
//            FirebaseApp.configure()
//            registerForPushNotifications()
//        }
    @State private var showSplash = true
#if DEBUG
  private let splashDelay: TimeInterval = 2
  #else
  private let splashDelay: TimeInterval = 0
  #endif

    
        
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 1) Main app
                ContentView()
                    .opacity(showSplash ? 0 : 1)
                    .environmentObject(authViewModel)
                    .environmentObject(usersViewModel)
                    .environmentObject(navigationState)
                    .environmentObject(storiesViewModel)
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveChatNotification)) { notif in
                        if let partnerId = notif.userInfo?["partnerId"] as? String {
                            navigationState.selectedTab = .messages
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigationState.chatPath = [partnerId]
                            }
                        }
                    }
                
                // 2) Overlay splash until we're ready
                if showSplash {
                    SplashView()
                }
            }
            .onAppear {
                configureWindow()
                
                // After at least splashDelay seconds, if onboarding is already checked, hide immediately.
                // Otherwise, we’ll hide in onReceive below.
                DispatchQueue.main.asyncAfter(deadline: .now() + splashDelay) {
                    if authViewModel.didCheckOnboarding {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                }
            }
            .onReceive(authViewModel.$didCheckOnboarding) { didCheck in
                // Once the onboarding check happens *and* splashDelay has passed, hide the splash
                guard didCheck else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + splashDelay) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveCaptionNotification)) { notif in
                            if let cid = notif.userInfo?["captionId"] as? String {
                                navigationState.selectedTab = .home
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    navigationState.deepLinkCaptionId = cid
                                }
                            }
                        }
            }
    }

            /// Match your theme color under SwiftUI so no white flash underflows.
            private func configureWindow() {
                guard let windowScene = UIApplication.shared.connectedScenes
                        .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
                      let window = windowScene.windows.first
                else { return }

                window.backgroundColor = UIColor(
                    red: 22/255, green: 29/255, blue: 35/255, alpha: 1
                )
            }
        }

        // A simple SwiftUI splash that matches your launch look
        struct SplashView: View {
            var body: some View {
                ZStack {
                    Color(red: 22/255, green: 29/255, blue: 35/255)
                        .ignoresSafeArea()

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
            }
        }
    
    private func setWindowBackground() {
            // grab the first scene’s window and recolor it
            guard let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
                  let window = windowScene.windows.first
            else { return }

            window.backgroundColor = UIColor(
                red: 22/255, green: 29/255, blue: 35/255, alpha: 1
            )
        }

extension Notification.Name {
    /// Posted when a “new message” notification is tapped, carrying the partner’s UID.
    static let didReceiveChatNotification = Notification.Name("didReceiveChatNotification")
    static let didReceiveCaptionNotification = Notification.Name("didReceiveCaptionNotification")
}
    
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // FCM & notification setup
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications(application: application)
        Messaging.messaging().delegate = self
        return true
    }

    // MARK: - Foreground notification display
    func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner & play sound even in foreground
        completionHandler([.banner, .sound])
    }

    // MARK: - Handle tap on notification
    func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      didReceive response: UNNotificationResponse,
      withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Look for our deep-link data
        if let partnerId = userInfo["chatPartnerId"] as? String {
            NotificationCenter.default.post(
              name: .didReceiveChatNotification,
              object: nil,
              userInfo: ["partnerId": partnerId]
            )
        }
        
        // ← new caption deep‑link
          if let captionId = userInfo["captionId"] as? String {
            NotificationCenter.default.post(
              name: .didReceiveCaptionNotification,
              object: nil,
              userInfo: ["captionId": captionId]
            )
          }

        completionHandler()
    }

    // MARK: - FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let token = fcmToken ?? ""
        print("FCM registration token: \(token)")
        NotificationCenter.default.post(
          name: Notification.Name("FCMToken"),
          object: nil,
          userInfo: ["token": token]
        )
    }

    // MARK: - APNs device token
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox) // .prod in release
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - Helpers
    private func registerForPushNotifications(application: UIApplication) {
        UNUserNotificationCenter
          .current()
          .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func application(
      _ application: UIApplication,
      didReceiveRemoteNotification userInfo: [AnyHashable : Any],
      fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Let FirebaseAuth handle silent notifications if needed
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
        } else {
            completionHandler(.newData)
        }
    }
}
