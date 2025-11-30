//
//  TrendingView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/19/25.
//

import SwiftUI

struct TrendingView: View {
    private let trendingSpot: (String, String) = ("Costa Rica", "🇨🇷")
    private let alternateTrendingSpot: (String, String) = ("Bali, Indonesia", "🇮🇩")
    @State private var highUVImageURL: URL?
    @State private var highUVSecondImageURL: URL?
    @State private var sharkImageURL: URL?
    @State private var sharkSecondImageURL: URL?
    @State private var beachImageURL: URL?
    @State private var beachSecondImageURL: URL?
    @State private var healthiestImageURL: URL?
    @State private var healthiestSecondImageURL: URL?
    @State private var rareAdventureImageURL: URL?
    @State private var rareAdventureSecondImageURL: URL?
    @State private var peopleImageURL: URL?
    @State private var peopleSecondImageURL: URL?
    @State private var moreFemalesImageURL: URL?
    @State private var moreFemalesSecondImageURL: URL?
    @State private var moreBoysImageURL: URL?
    @State private var moreBoysSecondImageURL: URL?
    @State private var foodImageURL: URL?
    @State private var foodSecondImageURL: URL?
    @State private var budgetImageURL: URL?
    @State private var budgetSecondImageURL: URL?
    @State private var lowCrowdsImageURL: URL?
    @State private var lowCrowdsSecondImageURL: URL?
    @State private var selectedTrendingIndex = 0
    @State private var isShowingFilters = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Trending")
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingFilters = true
                        }) {
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
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            
                            TabView(selection: $selectedTrendingIndex) {
                                HStack(spacing: 0) {
                                    TrendingCard(place: trendingSpot.0, flag: trendingSpot.1)
                                    Spacer()
                                }
                                .tag(0)
                                
                                HStack(spacing: 0) {
                                    TrendingCard(place: alternateTrendingSpot.0, flag: alternateTrendingSpot.1)
                                    Spacer()
                                }
                                .tag(1)
                            }
                            .frame(height: 180)
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .sensoryFeedback(.impact(weight: .medium), trigger: selectedTrendingIndex)
                            
                            HStack(spacing: 18) {
                                Image("airplane")
                                    .renderingMode(.template)
                                    .foregroundStyle(selectedTrendingIndex == 0 ? Colors.accent : Colors.secondaryText)
                                
                                Image("airplane")
                                    .renderingMode(.template)
                                    .foregroundStyle(selectedTrendingIndex == 1 ? Colors.accent : Colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            
                            HStack {
                                Text("High UV Places")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: highUVSecondImageURL) { image in
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
                                        Text("🇴🇲")
                                        Text("Muscat, Oman")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Strong midday sun")
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
                                highUVSecondImageURL = await UnsplashService.fetchImage(for: "Muscat Oman beach sun")
                            }
                            
                            HStack {
                                Text("Shark Activity")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: sharkSecondImageURL) { image in
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
                                        Text("🇿🇦")
                                        Text("Cape Town, South Africa")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Recent shark sightings")
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
                                sharkSecondImageURL = await UnsplashService.fetchImage(for: "Cape Town shark beach")
                            }
                            
                            HStack {
                                Text("Beach Escapes")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: beachSecondImageURL) { image in
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
                                        Text("🇺🇸")
                                        Text("Maui, Hawaii")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Warm Pacific water")
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
                                beachSecondImageURL = await UnsplashService.fetchImage(for: "Maui Hawaii beach")
                            }
                            
                            HStack {
                                Text("Healthiest Places")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: healthiestSecondImageURL) { image in
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
                                        Text("Sardinia, Italy")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Blue zone villages")
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
                                healthiestSecondImageURL = await UnsplashService.fetchImage(for: "Sardinia Italy coast")
                            }
                            
                            HStack {
                                Text("Highest Rarity Adventures")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: rareAdventureSecondImageURL) { image in
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
                                        Text("🇳🇿")
                                        Text("Queenstown, New Zealand")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("High alpine routes")
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
                                rareAdventureSecondImageURL = await UnsplashService.fetchImage(for: "Queenstown New Zealand mountains")
                            }
                            
                            HStack {
                                Text("People Your Age")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: peopleSecondImageURL) { image in
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
                                        Text("🇩🇪")
                                        Text("Berlin, Germany")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Busy nightlife crowd")
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
                                peopleSecondImageURL = await UnsplashService.fetchImage(for: "Berlin nightlife streets")
                            }
                            
                            HStack {
                                Text("More Females")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: moreFemalesSecondImageURL) { image in
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
                                        Text("🇱🇹")
                                        Text("Vilnius, Lithuania")
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
                                moreFemalesSecondImageURL = await UnsplashService.fetchImage(for: "Vilnius Lithuania old town")
                            }
                            
                            HStack {
                                Text("More Boys")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: moreBoysSecondImageURL) { image in
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
                                        Text("🇸🇦")
                                        Text("Riyadh, Saudi Arabia")
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
                                moreBoysSecondImageURL = await UnsplashService.fetchImage(for: "Riyadh skyline")
                            }
                            
                            HStack {
                                Text("Best Food Spots")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: foodSecondImageURL) { image in
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
                                        Text("Osaka, Japan")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Street food hubs")
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
                                foodSecondImageURL = await UnsplashService.fetchImage(for: "Osaka Japan street food")
                            }
                            
                            HStack {
                                Text("Budget Friendly")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: budgetSecondImageURL) { image in
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
                                        Text("🇵🇭")
                                        Text("Cebu, Philippines")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Budget island stays")
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
                                budgetSecondImageURL = await UnsplashService.fetchImage(for: "Cebu Philippines beach")
                            }
                            
                            HStack {
                                Text("Low Crowds")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
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

                            HStack(spacing: 14) {
                                AsyncImage(url: lowCrowdsSecondImageURL) { image in
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
                                        Text("🇳🇴")
                                        Text("Svalbard, Norway")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                    }

                                    Text("Quiet Arctic views")
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
                                lowCrowdsSecondImageURL = await UnsplashService.fetchImage(for: "Svalbard Arctic landscape")
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingFilters) {
                TrendingFilters()
            }
        }
    }
}

#Preview {
    TrendingView()
}
