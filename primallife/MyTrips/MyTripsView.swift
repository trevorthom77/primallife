//
//  AdventuresView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/18/25.
//

import SwiftUI

struct MyTripsView: View {
    @State private var tribeImageURL: URL?
    @State private var sunImageURL: URL?
    @State private var isShowingTrips = false
    @State private var isShowingTribeTrips = false
    
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
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    TravelCard()
                                    TravelCard(
                                        flag: "🇧🇸",
                                        location: "Bahamas",
                                        dates: "Mar 2–9",
                                        imageQuery: "Bahamas beach")
                                }
                            }
                            
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
                            }
                            .padding(12)
                            .frame(height: 96)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .task {
                                tribeImageURL = await UnsplashService.fetchImage(for: "Costa Rica beach")
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
