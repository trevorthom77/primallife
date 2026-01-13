//
//  SeeAllButton.swift
//  primallife
//
//  Created by Trevor Thompson on 11/17/25.
//

import SwiftUI

struct SeeAllButton: View {
    @State private var feedbackTrigger = 0
    
    var body: some View {
        Text("See All")
            .font(.travelDetail)
            .foregroundStyle(Colors.accent)
            .sensoryFeedback(.impact(weight: .medium), trigger: feedbackTrigger)
            .simultaneousGesture(TapGesture().onEnded {
                feedbackTrigger += 1
            })
    }
}
