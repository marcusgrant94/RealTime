//
//  RecentMessagesViewModel.swift
//  RealTime
//
//  Created by Marcus Grant on 7/2/25.
//

import Firebase
import Combine

class RecentMessagesViewModel: ObservableObject {
    @Published var recentMessages: [Message] = []
    private var listener: ListenerRegistration?

    func fetch() {
        let me = Auth.auth().currentUser?.uid ?? ""
        listener = Firestore
            .firestore()
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let all = docs.compactMap { try? $0.data(as: Message.self) }
                let filtered = all.filter {
                    $0.senderId == me || $0.recipientId == me
                }
                let grouped = Dictionary(
                    grouping: filtered,
                    by: { $0.senderId == me ? $0.recipientId : $0.senderId }
                )
                let recents = grouped.compactMap { _, msgs in msgs.first }
                let sorted = recents.sorted {
                    $0.timestamp.dateValue() > $1.timestamp.dateValue()
                }
                DispatchQueue.main.async {
                    self.recentMessages = sorted
                }
            }
    }

    func deleteConversation(with otherId: String) {
        let me = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()

        // 1) Grab all docs where (sender,recipient) is (me,otherId) or (otherId,me)
        let query = db
          .collection("messages")
          .whereField("senderId", in: [me, otherId])
          .whereField("recipientId", in: [me, otherId])

        query.getDocuments { snap, error in
          guard let docs = snap?.documents else { return }

          // 2) Batch-delete them
          let batch = db.batch()
          docs.forEach { batch.deleteDocument($0.reference) }
          batch.commit { err in
            if let err = err {
              print("❌ Error deleting conversation:", err)
            } else {
              DispatchQueue.main.async {
                // 3) Optimistically remove from your local summary
                self.recentMessages.removeAll {
                  // remove any summary for this conversation
                  let msg = $0
                  let convId = msg.senderId == me ? msg.recipientId : msg.senderId
                  return convId == otherId
                }
              }
            }
          }
        }
      }

      deinit { listener?.remove() }
}

