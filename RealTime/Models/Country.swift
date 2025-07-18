//
//  Country.swift
//  RealTime
//
//  Created by Marcus Grant on 6/29/25.
//


import SwiftUI

struct Country: Identifiable, Codable {
    var id = UUID()
    let name: String
    let flag: String
    let code: String
}
