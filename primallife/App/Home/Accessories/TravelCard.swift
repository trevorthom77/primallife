//
//  TravelCard.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI

struct TravelCard: View {
    @State private var imageURL: URL?
    var flag: String = "🇨🇷"
    var location: String = "Costa Rica"
    var dates: String = "Jan 12–20"
    var imageQuery: String = "Hawaii"
    var showsParticipants: Bool = true
    var height: CGFloat = 180
    
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
        .frame(width: 344, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text(flag)
                    Text(location)
                        .font(.travelTitle)
                        .foregroundStyle(Colors.card)
                }
                
                Spacer()
                
                Text(dates)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.card)
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
        .overlay(alignment: .bottomLeading) {
            if showsParticipants {
                HStack(spacing: -8) {
                    Image("profile4")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }
                    
                    Image("profile5")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }
                    
                    Image("profile6")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }
                    
                    Image("profile9")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }
                    
                    ZStack {
                        Circle()
                            .fill(Colors.background)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Circle()
                                    .stroke(Colors.card, lineWidth: 3)
                            }
                        
                        Text("67+")
                            .font(.custom(Fonts.semibold, size: 12))
                            .foregroundStyle(Colors.primaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .task {
            imageURL = await UnsplashService.fetchImage(for: imageQuery)
        }
    }
}

#Preview {
    TravelCard()
}
