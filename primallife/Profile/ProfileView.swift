//
//  ProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI

struct ProfileView: View {
    let name: String
    let homeCountry: String
    let countryFlag: String
    let tripsCount: Int
    let countriesCount: Int
    let worldPercent: Int
    let trips: [ProfileTrip]
    let countries: [ProfileCountry]
    let tribes: [ProfileTribe]
    let friends: [ProfileFriend]
    
    @Environment(\.dismiss) private var dismiss
    
    private let avatarSize: CGFloat = 140
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        BackButton {
                            dismiss()
                        }
                        
                        Spacer()
                        
                        Button("Edit") { }
                            .font(.travelDetail)
                            .foregroundStyle(Colors.accent)
                    }
                    
                    Image("profile1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 4)
                        }
                    
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Colors.accent)
                    }
                    
                    Text("\(countryFlag) \(homeCountry)")
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)
                    
                    HStack(spacing: 12) {
                        counterCard(title: "Trips", value: "\(tripsCount)")
                        counterCard(title: "Countries", value: "\(countriesCount)")
                        counterCard(title: "World", value: "\(worldPercent)%")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Past Trips")
                                .font(.custom(Fonts.semibold, size: 18))
                                .foregroundStyle(Colors.primaryText)

                            Spacer()

                            Button("See All") { }
                                .font(.travelDetail)
                                .foregroundStyle(Colors.accent)
                        }

                        VStack(spacing: 12) {
                            let displayedTrips = Array(trips.prefix(2))

                            ForEach(displayedTrips) { trip in
                                TravelCard(
                                    flag: trip.flag,
                                    location: trip.location,
                                    dates: trip.dates,
                                    imageQuery: trip.imageQuery,
                                    showsParticipants: false
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 180)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Countries")
                                .font(.custom(Fonts.semibold, size: 18))
                                .foregroundStyle(Colors.primaryText)

                            Spacer()

                            NavigationLink {
                                TravelStatsView()
                            } label: {
                                Text("See More")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                        }

                        VStack(spacing: 12) {
                            let displayedCountries = Array(countries.prefix(2))

                            ForEach(displayedCountries) { country in
                                TravelCard(
                                    flag: country.flag,
                                    location: country.name,
                                    dates: country.note,
                                    imageQuery: country.imageQuery,
                                    showsParticipants: false
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 180)
                            }

                            Button(action: { }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text("Add Country")
                                        .font(.travelDetail)
                                }
                                .foregroundStyle(Colors.tertiaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Tribes")
                                .font(.custom(Fonts.semibold, size: 18))
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                            
                            Button("See All") { }
                                .font(.travelDetail)
                                .foregroundStyle(Colors.accent)
                        }
                        
                        VStack(spacing: 10) {
                            ForEach(tribes) { tribe in
                                tribeRow(tribe)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Friends")
                                .font(.custom(Fonts.semibold, size: 18))
                                .foregroundStyle(Colors.primaryText)
                            
                            Spacer()
                            
                            Button("See All") { }
                                .font(.travelDetail)
                                .foregroundStyle(Colors.accent)
                        }
                        
                        VStack(spacing: 10) {
                            ForEach(friends) { friend in
                                friendRow(friend)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
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
    }
}

private func tribeRow(_ tribe: ProfileTribe) -> some View {
    HStack(spacing: 12) {
        Image(tribe.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Colors.card, lineWidth: 3)
            }
        
        VStack(alignment: .leading, spacing: 4) {
            Text(tribe.name)
                .font(.travelDetail)
                .foregroundStyle(Colors.primaryText)
            
            Text(tribe.status)
                .font(.custom(Fonts.regular, size: 14))
                .foregroundStyle(Colors.secondaryText)
        }
        
        Spacer()
    }
    .padding()
    .background(Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16))
}

private func counterCard(title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(value)
            .font(.travelTitle)
            .foregroundStyle(Colors.primaryText)
        
        Text(title)
            .font(.custom(Fonts.regular, size: 14))
            .foregroundStyle(Colors.secondaryText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16))
}

private func friendRow(_ friend: ProfileFriend) -> some View {
    HStack(spacing: 12) {
        Image(friend.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Colors.card, lineWidth: 3)
            }
        
        VStack(alignment: .leading, spacing: 4) {
            Text(friend.name)
                .font(.travelDetail)
                .foregroundStyle(Colors.primaryText)
            
            Text(friend.status)
                .font(.custom(Fonts.regular, size: 14))
                .foregroundStyle(Colors.secondaryText)
        }
        
        Spacer()
    }
    .padding()
    .background(Colors.card)
    .clipShape(RoundedRectangle(cornerRadius: 16))
}

struct ProfileFriend: Identifiable {
    let id = UUID()
    let imageName: String
    let name: String
    let status: String
}

struct ProfileTribe: Identifiable {
    let id = UUID()
    let imageName: String
    let name: String
    let status: String
}

struct ProfileCountry: Identifiable {
    let id = UUID()
    let flag: String
    let name: String
    let note: String
    let imageQuery: String
}

struct ProfileTrip: Identifiable {
    let id = UUID()
    let flag: String
    let location: String
    let dates: String
    let imageQuery: String
}

#Preview {
    ProfileView(
        name: "Mia",
        homeCountry: "Australia",
        countryFlag: "🇦🇺",
        tripsCount: 14,
        countriesCount: 9,
        worldPercent: 8,
        trips: [
            ProfileTrip(flag: "🇮🇩", location: "Bali", dates: "May 12–18", imageQuery: "Bali beach"),
            ProfileTrip(flag: "🇺🇸", location: "Big Sur", dates: "Jun 18–20", imageQuery: "Big Sur coast"),
            ProfileTrip(flag: "🇨🇭", location: "Swiss Alps", dates: "Jul 8–15", imageQuery: "Swiss Alps mountains")
        ],
        countries: [
            ProfileCountry(flag: "🇯🇵", name: "Japan", note: "May 12–18", imageQuery: "Japan skyline"),
            ProfileCountry(flag: "🇮🇹", name: "Italy", note: "Jun 18–20", imageQuery: "Italy coast")
        ],
        tribes: [
            ProfileTribe(imageName: "profile4", name: "Pacific Explorers", status: "Active"),
            ProfileTribe(imageName: "profile5", name: "Mountain Crew", status: "Planning")
        ],
        friends: [
            ProfileFriend(imageName: "profile1", name: "Ava", status: "Online"),
            ProfileFriend(imageName: "profile2", name: "Maya", status: "Planning"),
            ProfileFriend(imageName: "profile3", name: "Liam", status: "Offline")
        ]
    )
}
