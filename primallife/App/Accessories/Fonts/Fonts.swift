//
//  Fonts.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI

enum Fonts {
    static let semibold = "Epilogue-SemiBold"
    static let regular = "Epilogue-Regular"
}

extension Font {
    static var customTitle: Font {
        .custom(Fonts.semibold, size: 24)
    }
    
    static var onboardingTitle: Font {
        .custom(Fonts.semibold, size: 30)
    }
    
    static var travelTitle: Font {
        .custom(Fonts.semibold, size: 22)
    }
    
    static var travelBody: Font {
        .custom(Fonts.regular, size: 20)
    }
    
    static var travelDetail: Font {
        .custom(Fonts.semibold, size: 18)
    }
    
}
