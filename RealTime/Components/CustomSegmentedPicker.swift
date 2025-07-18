//
//  CustomSegmentedPicker.swift
//  RealTime
//
//  Created by Marcus Grant on 3/1/24.
//

import SwiftUI

struct CustomSegmentedPicker: View {
    @State private var selection: Int = 0
    @State private var showComingSoonAlert = false

    var body: some View {
        HStack {
            Button(action: {
                self.selection = 0
            }) {
                Text("Friends")
                    .foregroundColor(self.selection == 0 ? .black : .gray)
                    .padding()
                    .background(self.selection == 0 ? Color.gray : Color.clear)
                    .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)

            Button(action: {
                self.showComingSoonAlert = true
                // Do not update `selection`
            }) {
                Text("Subscribed")
                    .foregroundColor(.gray) // Always gray since it's disabled
                    .padding()
                    .background(Color.clear)
                    .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(25)
        .shadow(radius: 5)
        .alert("Coming Soon", isPresented: $showComingSoonAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The Subscribed feature is not available yet. Stay tuned!")
        }
    }
}



#Preview {
    CustomSegmentedPicker()
}
