//
//  ProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        GeometryReader { proxy in
            let cardHeight = proxy.size.height * 0.6
            let avatarSize: CGFloat = 120
            
            ZStack(alignment: .bottomLeading) {
                Colors.primaryText
                    .ignoresSafeArea()
                
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 32,
                        topTrailing: 32
                    )
                )
                .fill(Colors.card)
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                
                Image("profile1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Colors.card, lineWidth: 4)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, cardHeight - (avatarSize / 2))
            }
        }
    }
}

#Preview {
    ProfileView()
}
