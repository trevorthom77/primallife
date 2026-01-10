//
//  Colors.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI
import Foundation

enum Colors {
    static let accent = Color(hex: "#47c9db")
    static let ratingYellow = Color(hex: "#dbc247")
    static let ratingGreen = Color(hex: "#47db78")
    static let contentview = Color(hex: "#EFF2F7")
    static let background = Color(hex: "#F7FAFF")
    static let card = Color.white
    static let primaryText = Color(hex: "#232323")
    static let secondaryText = Color(hex: "#C1d8d9")
    static let tertiaryText = Color.white
    static let girlsPink = Color(hex: "#FF72B6")
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        
        let r, g, b, a: Double
        switch hexString.count {
        case 6:
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255,
                1
            )
        case 8:
            (r, g, b, a) = (
                Double((int >> 24) & 0xFF) / 255,
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
