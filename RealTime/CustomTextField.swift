//
//  CustomTextField.swift
//  RealTime
//
//  Created by Marcus Grant on 11/20/23.
//

import SwiftUI

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            // only show placeholder when empty, and push it extra far right
            if text.isEmpty {
                placeholder
                    .foregroundColor(.gray)
                    .padding(.leading, 24)  // ← make this > your field’s horizontal padding
            }

            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .padding(.horizontal, 16)   // field’s content inset
            .padding(.vertical,   12)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding(.horizontal, 4)      // outer margin
        .frame(height: 50)
    }
}
