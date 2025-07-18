//
//  ContactPicker.swift
//  RealTime
//
//  Created by Marcus Grant on 6/28/25.
//

import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            print("Selected contact: \(contact.givenName) \(contact.familyName)")
            // Process selected contact if needed
        }
    }
}
