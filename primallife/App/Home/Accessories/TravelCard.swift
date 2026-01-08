//
//  TravelCard.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI

struct TravelCard: View {
    @State private var imageURL: URL?
    @State private var photographerName: String?
    @State private var photographerProfileURL: URL?
    var flag: String = "🇨🇷"
    var location: String = "Costa Rica"
    var dates: String = "Jan 12–20"
    var imageQuery: String = "Costa Rica"
    var showsParticipants: Bool = true
    var showsAttribution: Bool = false
    var allowsHitTesting: Bool = false
    var prefetchedDetails: UnsplashImageDetails? = nil
    var width: CGFloat? = 344
    var height: CGFloat = 180
    var cornerRadius: CGFloat = 16
    @State private var didApplyPrefetch = false
    
    private let customImageNames = [
        "italy",
        "greece",
        "puerto rico",
        "costa rica",
        "africa",
        "antarctica",
        "asia",
        "europe",
        "north america",
        "oceania",
        "south america"
    ]
    
    private var customImageName: String? {
        let candidates = [
            location.trimmingCharacters(in: .whitespacesAndNewlines),
            imageQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        for name in customImageNames {
            for candidate in candidates where candidate.localizedCaseInsensitiveContains(name) {
                return name
            }
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            if let customImageName {
                Image(customImageName)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Colors.primaryText
                }
            } else {
                Colors.primaryText
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
        .overlay(alignment: .bottomTrailing) {
            if showsAttribution,
               let name = photographerName,
               !name.isEmpty,
               let profileURL = photographerProfileURL {
                Link(name, destination: profileURL)
                    .font(.custom(Fonts.semibold, size: 14))
                    .foregroundStyle(Colors.primaryText)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: showsParticipants ? 140 : 200, alignment: .trailing)
                    .padding(12)
            }
        }
        .allowsHitTesting(allowsHitTesting)
        .onAppear {
            guard customImageName == nil else { return }
            guard !didApplyPrefetch, let prefetchedDetails else { return }
            imageURL = prefetchedDetails.url
            photographerName = prefetchedDetails.photographerName
            photographerProfileURL = prefetchedDetails.photographerProfileURL
            didApplyPrefetch = true
        }
        .task {
            guard customImageName == nil else { return }
            guard imageURL == nil else { return }
            let details = await UnsplashService.fetchImageDetails(for: imageQuery)
            imageURL = details?.url
            photographerName = details?.photographerName
            photographerProfileURL = details?.photographerProfileURL
        }
    }
}

#Preview {
    TravelCard()
}
