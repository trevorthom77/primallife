//
//  BackButton.swift
//  primallife
//
//  Created by Trevor Thompson on 11/17/25.
//

import SwiftUI

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Colors.primaryText)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))

        }
    }
}
