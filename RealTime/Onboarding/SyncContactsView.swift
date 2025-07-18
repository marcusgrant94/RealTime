//
//  SyncContactsView.swift
//  RealTime
//
//  Created by Marcus Grant on 6/27/25.
//

import SwiftUI
import Contacts
import Firebase
import FirebaseFirestore

// handy little chunking extension to avoid Firestore’s 10-item "in" limit
fileprivate extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}

struct SyncContactsView: View {
  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var usersViewModel: UsersViewModel
  var onSyncCompleted: (() -> Void)?   // still call parent when done

  @State private var isContactsSynced    = false
  @State private var showingContactPicker = false

  let imageNames = ["person1","person2","person3","person4","person5","person6","person7"]
  private let customColor = Color(red: 22/255, green: 29/255, blue: 35/255)

  var body: some View {
    VStack(spacing: 30) {
      AutoScrollingHStack(images: imageNames, scrollSpeed: 30)
        .frame(height: 60)
        .padding(.top)

      Text("How do you want to share contacts?")
        .font(.headline)
        .multilineTextAlignment(.center)
        .foregroundColor(.white)

      VStack(spacing: 12) {
        Button("Select contacts") {
          showingContactPicker = true
        }
        .disabled(true)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .foregroundColor(.white)
        .sheet(isPresented: $showingContactPicker) {
          ContactPicker()
        }

        Button("Test Matches View") {
          // you can still use a mock fallback if you want
        }
        .foregroundColor(.blue)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
      }
      .padding(.horizontal)

      Spacer()

      VStack(spacing: 20) {
        Text("""
          Help us find your best friends.
          Allow **full access** to connect with the people who matter most.
          """)
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .foregroundColor(.white)

        Button(action: syncContacts) {
          HStack {
            Image(systemName: "person.3.fill")
            Text(isContactsSynced ? "Contacts Synced ✅" : "Sync Contacts")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.white)
          .foregroundColor(.black)
          .cornerRadius(12)
        }
        .disabled(isContactsSynced)

        Text("Your contact list remains private and 100% secure 🔒")
          .font(.caption)
          .foregroundColor(.gray)
      }
      .padding(.horizontal)

      Spacer()
    }
    .padding()
    .background(customColor.ignoresSafeArea())
    .sheet(isPresented: $navigationState.showMatchesFound) {
      MatchesFoundView(matchedUsers: navigationState.matchedUsers)
    }
  }

  private func syncContacts() {
    let store = CNContactStore()
    store.requestAccess(for: .contacts) { granted, error in
      guard granted, error == nil else {
        print("❌ Contacts permission denied or error: \(error?.localizedDescription ?? "")")
        return
      }

      let keys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor
      ]
      let req = CNContactFetchRequest(keysToFetch: keys)
      var contacts = [CNContact]()
      do {
        try store.enumerateContacts(with: req) { contact, _ in
          contacts.append(contact)
        }
        print("✅ Retrieved \(contacts.count) contacts.")
        uploadContacts(contacts)
      } catch {
        print("❌ Failed to fetch contacts: \(error)")
      }
    }
  }

  private func uploadContacts(_ contacts: [CNContact]) {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let db = Firestore.firestore()
    let group = DispatchGroup()

    // Upload each contact record
    for c in contacts {
      group.enter()
      let name = "\(c.givenName) \(c.familyName)"
      let phones = c.phoneNumbers.map { $0.value.stringValue }
      let data: [String:Any] = ["name": name, "phoneNumbers": phones]
      db.collection("users")
        .document(uid)
        .collection("syncedContacts")
        .addDocument(data: data) { _ in group.leave() }
    }

    group.notify(queue: .main) {
      self.isContactsSynced = true
      self.fetchMatchedUsers(from: contacts)
      onSyncCompleted?()
    }
  }

  private func fetchMatchedUsers(from contacts: [CNContact]) {
    // Gather all phone numbers
    let allPhones = contacts.flatMap { $0.phoneNumbers.map { $0.value.stringValue } }
    let db = Firestore.firestore()
    var foundUsers = [User]()

    // Firestore 'in' supports max 10, so we chunk
    let batches = allPhones.chunked(into: 10)
    let dispatch = DispatchGroup()

    for batch in batches {
      dispatch.enter()
      db.collection("users")
        .whereField("phoneNumber", in: batch)
        .getDocuments { snap, _ in
          if let docs = snap?.documents {
            let users = docs.compactMap { try? $0.data(as: User.self) }
            foundUsers.append(contentsOf: users)
          }
          dispatch.leave()
        }
    }

    dispatch.notify(queue: .main) {
      // remove duplicates
      let unique = Array(Set(foundUsers))
      navigationState.matchedUsers = unique
      navigationState.showMatchesFound = !unique.isEmpty
    }
  }
}



#Preview {
    SyncContactsView().environmentObject(NavigationState())
}

