//
//  SettingsView.swift
//  RealTime
//
//  Created by Marcus Grant on 1/5/24.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct SettingsView: View {
    init() {
        // Remove default Form/Section backgrounds and set custom color
        let customUIColor = UIColor(red: 22/255, green: 29/255, blue: 35/255, alpha: 1)
        UITableView.appearance().backgroundColor = customUIColor
        UITableViewCell.appearance().backgroundColor = customUIColor
        UITableViewHeaderFooterView.appearance().backgroundView = UIView()
        UITableViewHeaderFooterView.appearance().backgroundColor = customUIColor
        UITableView.appearance().sectionHeaderTopPadding = 0
        UITableView.appearance().separatorColor = .clear // Hide separators to avoid white lines
    }

    @EnvironmentObject var usersViewModel: UsersViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage? = nil
    @State private var inputImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showingConfirmationAlert = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var bioText = ""
    @State private var showSetBioView = false

    private var isPad: Bool { sizeClass == .regular }
    private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

    var body: some View {
        NavigationView {
            ZStack {
                customColor
                    .ignoresSafeArea()

                Form {
                    // MARK: Profile & User Info
                    Section {
                        profileCell
                        userInfoCell
                    }
                    .listRowBackground(customColor)

                    // MARK: About Me
                    Section(header: Text("About Me")
                        .font(.headline)
                        .foregroundColor(.white)
                    ) {
                        NameCard(usersViewModel: usersViewModel)
                            .padding(.vertical, isPad ? 12 : 6)
                    }
                    .listRowBackground(customColor)

                    // MARK: Self-introduction
                    Section(header: Text("Self‑introduction")
                        .font(.headline)
                        .foregroundColor(.white)
                    ) {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(minHeight: isPad ? 150 : 100)

                            if bioText.isEmpty {
                                Text("Add a short bio...")
                                    .italic()
                                    .foregroundColor(.gray)
                                    .padding(8)
                            } else {
                                Text(bioText)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .multilineTextAlignment(.leading)
                            }
                        }

                        Button("Edit") {
                            showSetBioView.toggle()
                        }
                        .foregroundColor(.blue)
                    }
                    .listRowBackground(customColor)

                    // MARK: Actions
                    Section {
                        Button(role: .destructive) {
                            showingConfirmationAlert = true
                        } label: {
                            Text("Log Out")
                                .foregroundColor(.red)
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(customColor)
                }
                .scrollContentBackground(.hidden)
                .background(customColor)
                .foregroundColor(.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                usersViewModel.fetchCurrentUser()
                bioText = usersViewModel.currentUser?.bio ?? ""
                loadImageFromURL()
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .alert("Log Out", isPresented: $showingConfirmationAlert) {
                Button("Log Out", role: .destructive) {
                    authViewModel.handleSignOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
                    .foregroundColor(.white)
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    isDeleting = true
                    authViewModel.deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action is permanent and cannot be undone.")
                    .foregroundColor(.white)
            }
            .overlay(
                Group {
                    if isDeleting {
                        ProgressView("Deleting Account...")
                            .padding()
                    }
                }, alignment: .center
            )
            .sheet(isPresented: $showSetBioView) {
                NavigationView {
                    SetBioView(usersViewModel: usersViewModel) {
                        showSetBioView = false
                    }
                }
            }
        }
    }

    // MARK: - Cells

    private var profileCell: some View {
        let size: CGFloat = isPad ? 180 : 100
        return HStack {
            Spacer()
            Button(action: { showingImagePicker = true }) {
                ZStack(alignment: .bottomTrailing) {
                    if isLoadingImage {
                        ProgressView()
                            .frame(width: size, height: size)
                    } else if let img = profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        profilePlaceholder
                            .frame(width: size, height: size)
                    }

                    Image(systemName: "camera.fill")
                        .font(.system(size: size * 0.12, weight: .bold))
                        .padding(size * 0.06)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        .offset(x: size * 0.03, y: size * 0.03)
                }
            }
            Spacer()
        }
        .listRowBackground(customColor)
    }

    private var userInfoCell: some View {
        VStack(spacing: isPad ? 8 : 4) {
            if let user = usersViewModel.currentUser {
                Text(user.name)
                    .font(isPad ? .title : .headline)
                    .foregroundColor(.white)
                Text(user.email)
                    .font(isPad ? .title3 : .subheadline)
                    .foregroundColor(.white)
            } else {
                Text("Not Signed In")
                    .font(isPad ? .title : .headline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .listRowBackground(customColor)
    }

    // MARK: - Helpers

    private var profilePlaceholder: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.5))
            if let initial = usersViewModel.currentUser?.name.first {
                Text(String(initial))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private func loadImageFromURL() {
        guard let urlString = usersViewModel.currentUser?.imageUrl,
              let url = URL(string: urlString) else { return }
        isLoadingImage = true
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    profileImage = uiImage
                    isLoadingImage = false
                }
            } else {
                DispatchQueue.main.async { isLoadingImage = false }
            }
        }
    }

    private func loadImage() {
        guard let input = inputImage,
              let user = usersViewModel.currentUser else { return }
        profileImage = input
        usersViewModel.uploadImage(input, for: user)
        usersViewModel.fetchCurrentUser()
    }
}











//#Preview {
//    SettingsView()
//}
