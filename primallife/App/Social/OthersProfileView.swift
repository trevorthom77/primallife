//
//  OthersProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI

struct OthersProfileView: View {
    let friend: Friend
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    Image(friend.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 4)
                        }
                    
                    HStack(spacing: 8) {
                        Text(friend.name)
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Colors.accent)
                    }
                    
                    Text("\(friend.countryFlag) \(friend.country)")
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)
                    
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Text("Add Friend")
                                .font(.custom(Fonts.semibold, size: 16))
                                .foregroundStyle(Colors.tertiaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Text("Message")
                                .font(.custom(Fonts.semibold, size: 16))
                                .foregroundStyle(Colors.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Colors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Me")
                            .font(.custom(Fonts.semibold, size: 18))
                            .foregroundStyle(Colors.primaryText)
                        
                        Text(friend.about)
                            .font(.custom(Fonts.regular, size: 16))
                            .foregroundStyle(Colors.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Likes")
                            .font(.custom(Fonts.semibold, size: 18))
                            .foregroundStyle(Colors.primaryText)
                        
                        Text("Likes")
                            .font(.custom(Fonts.regular, size: 16))
                            .foregroundStyle(Colors.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Trips")
                            .font(.custom(Fonts.semibold, size: 18))
                            .foregroundStyle(Colors.primaryText)
                        
                        VStack(spacing: 12) {
                            ForEach(friend.tripPlans) { plan in
                                TravelCard(
                                    flag: plan.flag,
                                    location: plan.location,
                                    dates: plan.dates,
                                    imageQuery: plan.imageQuery
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 180)
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 96)
            }
        }
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .topLeading) {
            BackButton {
                dismiss()
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
    }
}

#Preview {
    OthersProfileView(
        friend: Friend(
            name: "Ava",
            countryFlag: "🇦🇺",
            country: "Australia",
            imageName: "profile1",
            about: "Surf trips, sunrise runs, and finding hidden beaches.",
            tripPlans: [
                TripPlan(title: "Bali Surf", location: "Bali", flag: "🇮🇩", dates: "May 12–18", imageQuery: "Bali beach"),
                TripPlan(title: "Noosa Run", location: "Noosa", flag: "🇦🇺", dates: "Jun 4–6", imageQuery: "Noosa beach")
            ]
        )
    )
}
