//
//  Fonts.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI

enum Fonts {
    static let semibold = "Unbounded-SemiBold"
    static let regular = "Unbounded-Regular"
}

extension Font {
    static var customTitle: Font {
        .custom(Fonts.semibold, size: 24)
    }
    
    static var onboardingTitle: Font {
        .custom(Fonts.semibold, size: 28)
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

    static var tripsfont: Font {
        .custom(Fonts.semibold, size: 16)
    }

    static var badgeDetail: Font {
        .custom(Fonts.semibold, size: 12)
    }
    
    static var goBackFont: Font {
        .custom(Fonts.semibold, size: 18)
    }
    
    static var loadingTitle: Font {
        .custom(Fonts.semibold, size: 32)
    }
    
}
