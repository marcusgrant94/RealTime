//
//  SearchBar.swift
//  RealTime
//
//  Created by Marcus Grant on 7/1/25.
//

import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void

    // Your brand color
    private let backgroundUIColor = UIColor(
        red: 22/255, green: 29/255, blue: 35/255, alpha: 1
    )
    private let fieldBackgroundUIColor = UIColor(
        red: 44/255, green: 49/255, blue: 54/255, alpha: 1
    )

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onSearch: () -> Void

        init(text: Binding<String>, onSearch: @escaping () -> Void) {
            self._text    = text        // bind the backing storage
            self.onSearch = onSearch    // assign to your property
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            onSearch()
            searchBar.resignFirstResponder()
        }
    }


    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSearch: onSearchButtonClicked)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator

        // Style the bar
        searchBar.searchBarStyle = .minimal
        searchBar.isTranslucent = false
        searchBar.barTintColor = backgroundUIColor
        searchBar.backgroundImage = UIImage()       // remove default background

        // Style the text field
        let tf = searchBar.searchTextField
        tf.backgroundColor = fieldBackgroundUIColor
        tf.textColor = .white
        tf.tintColor = .white                       // cursor color
        tf.keyboardAppearance = .dark

        // Placeholder color
        tf.attributedPlaceholder = NSAttributedString(
            string: "Search...",
            attributes: [.foregroundColor: UIColor.gray]
        )

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}
