//
//  CountryPicker.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//

import SwiftUI
import Firebase


struct CountryPicker: View {
    @Binding var selectedCountry: Country

    let customColor = Color(red: 22 / 255.0, green: 29 / 255.0, blue: 35 / 255.0)
    let countries: [Country] = [
        Country(name: "United States", flag: "🇺🇸", code: "+1"),
        Country(name: "Canada", flag: "🇨🇦", code: "+1"),
        Country(name: "United Kingdom", flag: "🇬🇧", code: "+44"),
        Country(name: "Australia", flag: "🇦🇺", code: "+61"),
        Country(name: "New Zealand", flag: "🇳🇿", code: "+64"),
        Country(name: "Japan", flag: "🇯🇵", code: "+81"),
        Country(name: "South Korea", flag: "🇰🇷", code: "+82"),
        Country(name: "China", flag: "🇨🇳", code: "+86"),
        Country(name: "India", flag: "🇮🇳", code: "+91"),
        Country(name: "Germany", flag: "🇩🇪", code: "+49"),
        Country(name: "France", flag: "🇫🇷", code: "+33"),
        Country(name: "Italy", flag: "🇮🇹", code: "+39"),
        Country(name: "Spain", flag: "🇪🇸", code: "+34"),
        Country(name: "Netherlands", flag: "🇳🇱", code: "+31"),
        Country(name: "Sweden", flag: "🇸🇪", code: "+46"),
        Country(name: "Norway", flag: "🇳🇴", code: "+47"),
        Country(name: "Denmark", flag: "🇩🇰", code: "+45"),
        Country(name: "Finland", flag: "🇫🇮", code: "+358"),
        Country(name: "Brazil", flag: "🇧🇷", code: "+55"),
        Country(name: "Mexico", flag: "🇲🇽", code: "+52"),
        Country(name: "Russia", flag: "🇷🇺", code: "+7"),
        Country(name: "Turkey", flag: "🇹🇷", code: "+90"),
        Country(name: "South Africa", flag: "🇿🇦", code: "+27"),
        Country(name: "Nigeria", flag: "🇳🇬", code: "+234"),
        Country(name: "Egypt", flag: "🇪🇬", code: "+20"),
        Country(name: "Saudi Arabia", flag: "🇸🇦", code: "+966"),
        Country(name: "UAE", flag: "🇦🇪", code: "+971"),
        Country(name: "Singapore", flag: "🇸🇬", code: "+65"),
        Country(name: "Malaysia", flag: "🇲🇾", code: "+60"),
        Country(name: "Philippines", flag: "🇵🇭", code: "+63"),
        Country(name: "Thailand", flag: "🇹🇭", code: "+66"),
        Country(name: "Vietnam", flag: "🇻🇳", code: "+84"),
        Country(name: "Indonesia", flag: "🇮🇩", code: "+62"),
        Country(name: "Pakistan", flag: "🇵🇰", code: "+92"),
        Country(name: "Bangladesh", flag: "🇧🇩", code: "+880"),
        Country(name: "Argentina", flag: "🇦🇷", code: "+54"),
        Country(name: "Chile", flag: "🇨🇱", code: "+56"),
        Country(name: "Colombia", flag: "🇨🇴", code: "+57"),
        Country(name: "Peru", flag: "🇵🇪", code: "+51"),
        Country(name: "Portugal", flag: "🇵🇹", code: "+351"),
        Country(name: "Poland", flag: "🇵🇱", code: "+48"),
        Country(name: "Switzerland", flag: "🇨🇭", code: "+41"),
        Country(name: "Austria", flag: "🇦🇹", code: "+43"),
        Country(name: "Belgium", flag: "🇧🇪", code: "+32"),
        Country(name: "Ireland", flag: "🇮🇪", code: "+353"),
        Country(name: "Greece", flag: "🇬🇷", code: "+30"),
        Country(name: "Israel", flag: "🇮🇱", code: "+972"),
        Country(name: "Ukraine", flag: "🇺🇦", code: "+380"),
        Country(name: "Romania", flag: "🇷🇴", code: "+40"),
        Country(name: "Czech Republic", flag: "🇨🇿", code: "+420"),
        Country(name: "Hungary", flag: "🇭🇺", code: "+36"),
    ]
    
    init(selectedCountry: Binding<Country>) {
        self._selectedCountry = selectedCountry

        let navBar = UINavigationBarAppearance()
        navBar.backgroundColor = UIColor(red:22/255, green:29/255, blue:35/255, alpha:1)
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance   = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar

        UITableView.appearance().backgroundColor = UIColor(red:22/255, green:29/255, blue:35/255, alpha:1)
      }

        var body: some View {
            NavigationView {
                List(countries, id: \.name) { country in
                    HStack {
                        Text(country.flag)
                        Text(country.name)
                            .foregroundColor(.white)
                        Spacer()
                        Text(country.code)
                            .foregroundColor(.white)
                    }
                    .contentShape(Rectangle())        // make the whole row tappable
                    .listRowBackground(customColor)   // row’s background
                    .onTapGesture {
                        selectedCountry = country
                        // dismiss:
                        UIApplication.shared.windows
                          .first { $0.isKeyWindow }?
                          .rootViewController?
                          .dismiss(animated: true)
                    }
                }
                .listStyle(.plain)                       // remove group insets
                .scrollContentBackground(.hidden)        // iOS 16+: no extra behind-list background
                .background(customColor)                 // safety on older iOS
                .navigationTitle("Select Country")
            }
            // 3) Also color any area outside the nav/list:
            .background(customColor.ignoresSafeArea())
        }
    }

