//
//  TrendingCard.swift
//  primallife
//
//  Created by Trevor Thompson on 11/20/25.
//

import SwiftUI

struct TrendingCard: View {
    let place: String
    let flag: String
    @State private var imageURL: URL?
    
    var body: some View {
        ZStack {
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Colors.card
                }
            } else {
                Colors.card
            }
        }
        .frame(width: 344, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 8) {
                Text(flag)
                Text(place)
                    .font(.travelTitle)
                    .foregroundStyle(Colors.card)
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
        .task {
            imageURL = await UnsplashService.fetchImage(for: place)
        }
    }
}

#Preview {
    TrendingCard(place: "Lisbon", flag: "🇵🇹")
}
