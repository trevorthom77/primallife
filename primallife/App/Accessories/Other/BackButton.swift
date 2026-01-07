//
//  BackButton.swift
//  primallife
//
//  Created by Trevor Thompson on 11/17/25.
//

import SwiftUI

struct BackButton: View {
    let action: () -> Void
    @State private var feedbackToggle = false
    
    var body: some View {
        Button {
            feedbackToggle.toggle()
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Colors.primaryText)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))

        }
        .zIndex(1)
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackToggle)
    }
}
