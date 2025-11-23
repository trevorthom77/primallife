//
//  TrendingView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/19/25.
//

import SwiftUI

struct TrendingView: View {
    private let trendingSpot: (String, String) = ("Costa Rica", "🇨🇷")
    @State private var highUVImageURL: URL?
    @State private var sharkImageURL: URL?
    @State private var beachImageURL: URL?
    @State private var healthiestImageURL: URL?
    @State private var rareAdventureImageURL: URL?
    @State private var peopleImageURL: URL?
    @State private var moreFemalesImageURL: URL?
    @State private var moreBoysImageURL: URL?
    @State private var foodImageURL: URL?
    @State private var budgetImageURL: URL?
    @State private var lowCrowdsImageURL: URL?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Trending")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    Spacer()
                    
                    Button(action: { }) {
                        Text("Filter")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.tertiaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Colors.accent)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Trending Locations")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        
                        TrendingCard(place: trendingSpot.0, flag: trendingSpot.1)
                        
                        HStack {
                            Text("High UV Places")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: highUVImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇦🇺")
                                    Text("Darwin, Australia")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Extreme UV mid day")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            highUVImageURL = await UnsplashService.fetchImage(for: "Darwin Australia beach sun")
                        }
                        
                        HStack {
                            Text("Shark Activity")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: sharkImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇷🇪")
                                    Text("Reunion Island")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Recent shark reports")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            sharkImageURL = await UnsplashService.fetchImage(for: "Reunion Island ocean shark")
                        }
                        
                        HStack {
                            Text("Beach Escapes")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: beachImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇲🇽")
                                    Text("Tulum, Mexico")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Calm Caribbean water")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            beachImageURL = await UnsplashService.fetchImage(for: "Tulum beach")
                        }
                        
                        HStack {
                            Text("Healthiest Places")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: healthiestImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇯🇵")
                                    Text("Okinawa, Japan")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Long-living community")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            healthiestImageURL = await UnsplashService.fetchImage(for: "Okinawa Japan beach")
                        }
                        
                        HStack {
                            Text("Highest Rarity Adventures")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: rareAdventureImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇨🇱")
                                    Text("Patagonia, Chile")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Remote alpine trails")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            rareAdventureImageURL = await UnsplashService.fetchImage(for: "Patagonia Chile mountains")
                        }
                        
                        HStack {
                            Text("People Your Age")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: peopleImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇪🇸")
                                    Text("Barcelona, Spain")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Active social scene")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            peopleImageURL = await UnsplashService.fetchImage(for: "Barcelona Spain city beach")
                        }
                        
                        HStack {
                            Text("More Females")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: moreFemalesImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇱🇻")
                                    Text("Riga, Latvia")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("More female travelers")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            moreFemalesImageURL = await UnsplashService.fetchImage(for: "Riga Latvia city")
                        }
                        
                        HStack {
                            Text("More Boys")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: moreBoysImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇶🇦")
                                    Text("Doha, Qatar")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("More male travelers")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            moreBoysImageURL = await UnsplashService.fetchImage(for: "Doha Qatar skyline")
                        }
                        
                        HStack {
                            Text("Best Food Spots")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: foodImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇮🇹")
                                    Text("Bologna, Italy")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Classic food markets")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            foodImageURL = await UnsplashService.fetchImage(for: "Bologna Italy food market")
                        }
                        
                        HStack {
                            Text("Budget Friendly")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: budgetImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇻🇳")
                                    Text("Da Nang, Vietnam")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Affordable beach stays")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            budgetImageURL = await UnsplashService.fetchImage(for: "Da Nang Vietnam beach")
                        }
                        
                        HStack {
                            Text("Low Crowds")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        HStack(spacing: 14) {
                            AsyncImage(url: lowCrowdsImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Colors.card
                            }
                            .frame(width: 104, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("🇫🇴")
                                    Text("Faroe Islands")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                
                                Text("Quiet cliff views")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .frame(height: 112)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .task {
                            lowCrowdsImageURL = await UnsplashService.fetchImage(for: "Faroe Islands cliffs")
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: 96)
                }
            }
        }
    }
}

#Preview {
    TrendingView()
}
