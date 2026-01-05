//
//  OthersProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import Supabase

struct OthersProfileView: View {
    let userID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var profile: UserProfile?
    @State private var trips: [Trip] = []
    @State private var isLoadingTrips = false
    @State private var isShowingSeeAllSheet = false

    init(userID: UUID) {
        self.userID = userID
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
                        Button(action: {
                            Task {
                                await sendFriendRequest()
                            }
                        }) {
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
                        HStack {
                            Text("Upcoming Trips")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            Spacer()

                            Button("See All") {
                                isShowingSeeAllSheet = true
                            }
                                .font(.travelDetail)
                                .foregroundStyle(Colors.accent)
                        }
                        
                        if isLoadingTrips && trips.isEmpty {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Colors.secondaryText.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if let trip = trips.first {
                            TravelCard(
                                flag: tripFlag(for: trip),
                                location: tripLocation(for: trip),
                                dates: tripDateRange(for: trip),
                                imageQuery: tripImageQuery(for: trip),
                                showsParticipants: false,
                                width: nil,
                                height: 140
                            )
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 140)
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
        .sheet(isPresented: $isShowingSeeAllSheet) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(trips) { trip in
                            TravelCard(
                                flag: tripFlag(for: trip),
                                location: tripLocation(for: trip),
                                dates: tripDateRange(for: trip),
                                imageQuery: tripImageQuery(for: trip),
                                showsParticipants: false,
                                width: nil,
                                height: 140
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 140)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .task(id: userID) {
            guard let userID else { return }
            await MainActor.run {
                if trips.isEmpty {
                    isLoadingTrips = true
                }
            }
            await loadProfile(for: userID)
            await loadTrips(for: userID)
            await MainActor.run {
                isLoadingTrips = false
            }
        }
    }

    private var displayName: String {
        profile?.fullName ?? ""
    }

    private var originDisplay: String? {
        if let profile,
           let flag = profile.originFlag,
           let name = profile.originName {
            return "\(flag) \(name)"
        }
        return nil
    }

    private var aboutText: String {
        if let profile {
            return profile.bio
        }
        return ""
    }

    private var likesText: String? {
        if let profile {
            let likes = profile.interests.joined(separator: ", ")
            return likes.isEmpty ? nil : likes
        }

        return nil
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

    private func loadTrips(for userID: UUID) async {
        guard let supabase else { return }

        do {
            let fetchedTrips: [Trip] = try await supabase
                .from("mytrips")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run {
                trips = fetchedTrips
            }
        } catch {
            return
        }
    }

    private func tripFlag(for trip: Trip) -> String {
        let emojiScalars = trip.destination.unicodeScalars.filter { $0.properties.isEmoji }
        return String(String.UnicodeScalarView(emojiScalars))
            .trimmingCharacters(in: .whitespaces)
    }

    private func tripLocation(for trip: Trip) -> String {
        let filteredScalars = trip.destination.unicodeScalars.filter { !$0.properties.isEmoji }
        return String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespaces)
    }

    private func tripImageQuery(for trip: Trip) -> String {
        let cleaned = tripLocation(for: trip)
        return cleaned.isEmpty ? trip.destination : cleaned
    }

    private func tripDateRange(for trip: Trip) -> String {
        let start = trip.checkIn.formatted(.dateTime.month(.abbreviated).day())
        let end = trip.returnDate.formatted(.dateTime.month(.abbreviated).day())
        return start == end ? start : "\(start)–\(end)"
    }

    private func sendFriendRequest() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id,
              let receiverID = userID,
              currentUserID != receiverID
        else { return }

        struct FriendRequestInsert: Encodable {
            let requesterID: UUID
            let receiverID: UUID

            enum CodingKeys: String, CodingKey {
                case requesterID = "requester_id"
                case receiverID = "receiver_id"
            }
        }

        do {
            try await supabase
                .from("friend_requests")
                .insert(
                    FriendRequestInsert(
                        requesterID: currentUserID,
                        receiverID: receiverID
                    )
                )
                .execute()
        } catch {
            return
        }
    }
}
