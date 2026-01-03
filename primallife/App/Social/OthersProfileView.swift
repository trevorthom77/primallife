//
//  OthersProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import Supabase

struct OthersProfileView: View {
    let friend: Friend?
    let userID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var profile: UserProfile?

    init(friend: Friend) {
        self.friend = friend
        self.userID = nil
    }

    init(userID: UUID) {
        self.userID = userID
        self.friend = nil
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    avatarView
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 4)
                        }
                    
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Colors.accent)
                    }
                    
                    if let originDisplay {
                        Text(originDisplay)
                            .font(.custom(Fonts.regular, size: 16))
                            .foregroundStyle(Colors.secondaryText)
                    }
                    
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
                        
                        if !aboutText.isEmpty {
                            Text(aboutText)
                                .font(.custom(Fonts.regular, size: 16))
                                .foregroundStyle(Colors.secondaryText)
                        }
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
                        
                        if let likesText {
                            Text(likesText)
                                .font(.custom(Fonts.regular, size: 16))
                                .foregroundStyle(Colors.secondaryText)
                        }
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
                        
                        if !tripPlans.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(tripPlans) { plan in
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
        .task(id: userID) {
            guard let userID else { return }
            await loadProfile(for: userID)
        }
    }

    private var displayName: String {
        profile?.fullName ?? friend?.name ?? ""
    }

    private var originDisplay: String? {
        if let profile,
           let flag = profile.originFlag,
           let name = profile.originName {
            return "\(flag) \(name)"
        }

        if let friend {
            return "\(friend.countryFlag) \(friend.country)"
        }

        return nil
    }

    private var aboutText: String {
        if let profile {
            return profile.bio
        }

        return friend?.about ?? ""
    }

    private var likesText: String? {
        if let profile {
            let likes = profile.interests.joined(separator: ", ")
            return likes.isEmpty ? nil : likes
        }

        return friend != nil ? "Likes" : nil
    }

    private var tripPlans: [TripPlan] {
        friend?.tripPlans ?? []
    }

    private var avatarURL: URL? {
        profile?.avatarURL(using: supabase)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
        } else if let imageName = friend?.imageName {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }

    private func loadProfile(for userID: UUID) async {
        guard let supabase else { return }

        do {
            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value

            await MainActor.run {
                profile = profiles.first
            }
        } catch {
            return
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
