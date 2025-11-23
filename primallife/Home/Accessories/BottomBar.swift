//
//  BottomBar.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI

struct BottomBar: View {
    @Binding var selectedTab: String
    @State private var feedbackToggle = false
    
    var body: some View {
        Rectangle()
            .fill(Colors.card)
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .overlay(barContent)
            .background(Colors.card)
    }
    
    private var barContent: some View {
        HStack {
            barIcon(name: "map")
            
            Spacer()

            barIcon(name: "globe")

            Spacer()

            barIcon(name: "airplane")
            
            Spacer()
            
            barIcon(name: "message")
        }
        .padding(.horizontal, 50)
    }
    
    private func barIcon(name: String, size: CGFloat = 24) -> some View {
        Button {
            selectedTab = name
            feedbackToggle.toggle()
        } label: {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(selectedTab == name ? Colors.accent : Colors.secondaryText)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackToggle)
        .buttonStyle(.plain)
    }
}

#Preview {
    BottomBar(selectedTab: .constant("map"))
        .background(Colors.background)
}
