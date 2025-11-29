//
//  AdventuresView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/18/25.
//

import SwiftUI

struct MyTripsView: View {
    @State private var tribeImageURL: URL?
    @State private var secondTribeImageURL: URL?
    @State private var sunImageURL: URL?
    @State private var groundingImageURL: URL?
    @State private var isShowingTrips = false
    @State private var isShowingTribeTrips = false
    @State private var selectedTripIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Trips")
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingTrips = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Colors.accent)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "plus")
                                    .foregroundStyle(Colors.tertiaryText)
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Colors.background)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Trip Plans")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            
                            TabView(selection: $selectedTripIndex) {
                                HStack(spacing: 0) {
                                    TravelCard()
                                    Spacer()
                                }
                                .tag(0)
                                
                                HStack(spacing: 0) {
                                    TravelCard(
                                        flag: "🇧🇸",
                                        location: "Bahamas",
                                        dates: "Mar 2–9",
                                        imageQuery: "Bahamas beach")
                                    Spacer()
                                }
                                .tag(1)
                            }
                            .frame(height: 180)
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .sensoryFeedback(.impact(weight: .medium), trigger: selectedTripIndex)
                            
                            HStack(spacing: 18) {
                                Image("airplane")
                                    .renderingMode(.template)
                                    .foregroundStyle(selectedTripIndex == 0 ? Colors.accent : Colors.secondaryText)
                                    
                                Image("airplane")
                                    .renderingMode(.template)
                                    .foregroundStyle(selectedTripIndex == 1 ? Colors.accent : Colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            
                            HStack {
                                Text("Costa Rica Tribes")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            .padding(.top, 16)
                            
                            NavigationLink {
                                TribesSocialView(
                                    imageURL: tribeImageURL,
                                    title: "Party Tonight Costa Rica",
                                    location: "Costa Rica",
                                    flag: "🇨🇷",
                                    date: "Dec 5–9, 2025"
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: tribeImageURL) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Colors.card
                                        }
                                        .frame(width: 88, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Party Tonight Costa Rica")
                                                .font(.travelDetail)
                                                .foregroundStyle(Colors.primaryText)
                                            
                                            HStack(spacing: 6) {
                                                Text("🇨🇷")
                                                Text("Costa Rica")
                                                    .font(.travelDetail)
                                                    .foregroundStyle(Colors.secondaryText)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Colors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                    HStack(spacing: -8) {
                                        Image("profile1")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                        
                                        Image("profile2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                        
                                        Image("profile3")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                        
                                        ZStack {
                                            Circle()
                                                .fill(Colors.background)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }
                                            
                                            Text("67+")
                                                .font(.custom(Fonts.semibold, size: 12))
                                                .foregroundStyle(Colors.primaryText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                            .buttonStyle(.plain)
                            .task {
                                tribeImageURL = await UnsplashService.fetchImage(for: "Costa Rica beach")
                            }

                            NavigationLink {
                                TribesSocialView(
                                    imageURL: secondTribeImageURL,
                                    title: "Rainforest Tribe Costa Rica",
                                    location: "Costa Rica",
                                    flag: "🇨🇷",
                                    date: "Dec 5–9, 2025"
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: secondTribeImageURL) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Colors.card
                                        }
                                        .frame(width: 88, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Rainforest Tribe Costa Rica")
                                                .font(.travelDetail)
                                                .foregroundStyle(Colors.primaryText)

                                            HStack(spacing: 6) {
                                                Text("🇨🇷")
                                                Text("Costa Rica")
                                                    .font(.travelDetail)
                                                    .foregroundStyle(Colors.secondaryText)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Colors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                    HStack(spacing: -8) {
                                        Image("profile1")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        Image("profile2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        Image("profile3")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        ZStack {
                                            Circle()
                                                .fill(Colors.background)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }

                                            Text("54+")
                                                .font(.custom(Fonts.semibold, size: 12))
                                                .foregroundStyle(Colors.primaryText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                            .buttonStyle(.plain)
                            .task {
                                secondTribeImageURL = await UnsplashService.fetchImage(for: "Costa Rica jungle")
                            }

                            Button(action: {
                                isShowingTribeTrips = true
                            }) {
                                Text("Add Tribe")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.tertiaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Colors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            
                            HStack {
                                Text("Adventures")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            .padding(.top, 24)
                            
                            HStack(spacing: 12) {
                                AsyncImage(url: sunImageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Colors.card
                                }
                                .frame(width: 88, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sun")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Text("Rare")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.tertiaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Colors.accent.opacity(0.6))
                                        )
                                }
                                
                                Spacer()
                                
                                Image("boat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                            }
                            .padding(12)
                            .frame(height: 96)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .task {
                                sunImageURL = await UnsplashService.fetchImage(for: "sunset beach")
                            }

                            HStack(spacing: 12) {
                                AsyncImage(url: groundingImageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Colors.card
                                }
                                .frame(width: 88, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Grounding")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)

                                    Text("Legendary")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.tertiaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Colors.legendary)
                                        )
                                }

                                Spacer()

                                Image("boat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                            }
                            .padding(12)
                            .frame(height: 96)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .task {
                                groundingImageURL = await UnsplashService.fetchImage(for: "forest trail")
                            }

                            HStack {
                                Text("Explorers going")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            .padding(.top, 16)
                            
                            HStack(spacing: 12) {
                                Image("profile7")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Ava")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                        
                                        Text("27")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text("🇲🇽")
                                        Text("Mexico")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            HStack(spacing: 12) {
                                Image("profile8")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Leo")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        Text("25")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }

                                    HStack(spacing: 8) {
                                        Text("🇧🇷")
                                        Text("Brazil")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            HStack(spacing: 12) {
                                Image("profile9")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Maya")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        Text("31")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }

                                    HStack(spacing: 8) {
                                        Text("🇨🇷")
                                        Text("Costa Rica")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
            .navigationDestination(isPresented: $isShowingTrips) {
                TripsView()
            }
            .navigationDestination(isPresented: $isShowingTribeTrips) {
                TribeTripsView()
            }
        }
    }
}

#Preview {
    MyTripsView()
}
