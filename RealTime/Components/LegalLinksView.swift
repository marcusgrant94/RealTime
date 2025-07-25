//
//  legalLinksView.swift
//  RealTime
//
//  Created by Marcus Grant on 7/19/25.
//

import SwiftUI

struct LegalLinksView: View {
    private let privacyURL = URL(string: "https://www.freeprivacypolicy.com/live/d49f26c8-d0ba-4dbb-a665-c3dbb68e3786")!
    private let termsURL   = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        VStack(spacing: 4) {
            Text("By using RealTime, you agree to our")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Link("Privacy Policy", destination: privacyURL)
                    .font(.footnote)
                    .foregroundColor(.blue)
                Text("and")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Link("Terms of Service", destination: termsURL)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
    }
}


