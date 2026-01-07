//
//  ProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import Supabase

struct UserProfile: Decodable, Identifiable {
    let id: UUID
    let fullName: String
    let origin: String?
    let gender: String?
    let bio: String
    let avatarPath: String?
    let meetingPreference: String?
    let meetingUpPreference: String?
    let splitExpensesPreference: String?
    let travelDescription: String?
    let upcomingDestination: String
    let upcomingArrivalDate: String?
    let upcomingDepartingDate: String?
    let languages: [String]
    let interests: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case origin
        case gender
        case bio
        case avatarPath = "avatar_url"
        case meetingPreference = "meeting_preference"
        case meetingUpPreference = "meeting_up_preference"
        case splitExpensesPreference = "split_expenses_preference"
        case travelDescription = "travel_description"
        case upcomingDestination = "upcoming_destination"
        case upcomingArrivalDate = "upcoming_arrival_date"
        case upcomingDepartingDate = "upcoming_departing_date"
        case languages
        case interests
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fullName = try container.decode(String.self, forKey: .fullName)
        origin = try container.decodeIfPresent(String.self, forKey: .origin)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        bio = try container.decode(String.self, forKey: .bio)
        avatarPath = try container.decodeIfPresent(String.self, forKey: .avatarPath)
        meetingPreference = try container.decodeIfPresent(String.self, forKey: .meetingPreference)
        meetingUpPreference = try container.decodeIfPresent(String.self, forKey: .meetingUpPreference)
        splitExpensesPreference = try container.decodeIfPresent(String.self, forKey: .splitExpensesPreference)
        travelDescription = try container.decodeIfPresent(String.self, forKey: .travelDescription)
        upcomingDestination = try container.decode(String.self, forKey: .upcomingDestination)
        upcomingArrivalDate = try container.decodeIfPresent(String.self, forKey: .upcomingArrivalDate)
        upcomingDepartingDate = try container.decodeIfPresent(String.self, forKey: .upcomingDepartingDate)
        languages = try container.decodeIfPresent([String].self, forKey: .languages) ?? []
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
    }
    
    var originCountry: Country? {
        guard let origin else { return nil }
        return CountryDatabase.all.first(where: { $0.id == origin })
    }
    
    var originFlag: String? {
        originCountry?.flag
    }
    
    var originName: String? {
        originCountry?.name
    }
    
    func avatarURL(using supabase: SupabaseClient?) -> URL? {
        guard let supabase, let avatarPath else { return nil }
        
        do {
            return try supabase.storage
                .from("profile-photos")
                .getPublicURL(path: avatarPath)
        } catch {
            return nil
        }
    }
}

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
    
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var joinedTribes: [ProfileTribe] = []
    @State private var isLoadingTribes = false
    
    private let avatarSize: CGFloat = 140
    
    private var profile: UserProfile? {
        profileStore.profile
    }

    private var friends: [UserProfile] {
        profileStore.cachedFriends
    }

    private var displayedTribes: [ProfileTribe] {
        joinedTribes.isEmpty ? tribes : joinedTribes
    }
    
    private var originDisplay: String? {
        guard
            let profile,
            let flag = profile.originFlag,
            let name = profile.originName
        else {
            return nil
        }
        
        return "\(flag) \(name)"
    }
    
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
                        
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Colors.primaryText)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Colors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    HStack {
                        Spacer()

                        Button("Edit") { }
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .buttonStyle(.plain)
                    }

                    avatarView
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 4)
                        }
                    
                    HStack(spacing: 8) {
                        Text(profile?.fullName ?? name)
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
                                    showsParticipants: false,
                                    height: 150
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    showsParticipants: false,
                                    height: 150
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                            ForEach(displayedTribes) { tribe in
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
                        
                        if !friends.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(Array(friends.prefix(3))) { friend in
                                    NavigationLink {
                                        OthersProfileView(userID: friend.id)
                                    } label: {
                                        friendCard(friend)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            Text("No friends yet")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
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
        .task {
            await loadFriends()
            await loadTribes()
        }
    }

    @MainActor
    private func loadFriends() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        if profileStore.hasLoadedFriends {
            return
        }

        do {
            let userRows: [FriendRow] = try await supabase
                .from("friends")
                .select("user_id, friend_id")
                .eq("user_id", value: currentUserID.uuidString)
                .execute()
                .value

            let friendRows: [FriendRow] = try await supabase
                .from("friends")
                .select("user_id, friend_id")
                .eq("friend_id", value: currentUserID.uuidString)
                .execute()
                .value

            let friendIDs = Set(userRows.map { $0.friendID } + friendRows.map { $0.userID })
            if friendIDs.isEmpty {
                profileStore.cachedFriends = []
                profileStore.hasLoadedFriends = true
                return
            }

            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .in("id", values: friendIDs.map { $0.uuidString })
                .execute()
                .value

            profileStore.cachedFriends = profiles
            profileStore.hasLoadedFriends = true
        } catch {
            return
        }
    }

    @MainActor
    private func loadTribes() async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id,
              !isLoadingTribes else { return }

        isLoadingTribes = true
        defer { isLoadingTribes = false }

        do {
            let joinRows: [ProfileTribeJoinRow] = try await supabase
                .from("tribes_join")
                .select("tribe_id")
                .eq("id", value: userID.uuidString)
                .execute()
                .value

            let tribeIDs = joinRows.map { $0.tribeID }
            if tribeIDs.isEmpty {
                joinedTribes = []
                return
            }

            let tribeIDStrings = tribeIDs.map { $0.uuidString }
            let tribes: [ProfileTribeRow] = try await supabase
                .from("tribes")
                .select("id, name, destination, photo_url")
                .in("id", values: tribeIDStrings)
                .execute()
                .value

            joinedTribes = tribes.map { tribe in
                ProfileTribe(
                    id: tribe.id,
                    imageName: "",
                    name: tribe.name,
                    status: tribe.destination,
                    photoURL: tribe.photoURL
                )
            }
        } catch {
            return
        }
    }
}

private extension ProfileView {
    @ViewBuilder
    var avatarView: some View {
        let avatarURL = profile?.avatarURL(using: supabase)
        
        if let avatarURL,
           let cachedImage = profileStore.cachedAvatarImage,
           profileStore.cachedAvatarURL == avatarURL {
            cachedImage
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            profileStore.cacheAvatar(image, url: avatarURL)
                        }
                default:
                    placeholderAvatar
                }
            }
        } else {
            placeholderAvatar
        }
    }
    
    var placeholderAvatar: some View {
        Color.clear
    }

    private func friendCard(_ friend: UserProfile) -> some View {
        HStack(spacing: 12) {
            friendAvatar(for: friend)
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.fullName)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                if let origin = friendOriginDisplay(for: friend) {
                    Text(origin)
                        .font(.custom(Fonts.regular, size: 14))
                        .foregroundStyle(Colors.secondaryText)
                }
            }

            Spacer()
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func friendAvatar(for friend: UserProfile) -> some View {
        if let avatarURL = friend.avatarURL(using: supabase) {
            if let cachedImage = cachedFriendImage(for: avatarURL) {
                cachedImage
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                if profileStore.cachedFriendImages[avatarURL] == nil {
                                    profileStore.cacheFriendImage(image, url: avatarURL)
                                }
                            }
                    case .empty:
                        Colors.secondaryText.opacity(0.3)
                    default:
                        Colors.secondaryText.opacity(0.3)
                    }
                }
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }

    private func cachedFriendImage(for url: URL) -> Image? {
        profileStore.cachedFriendImages[url]
    }

    private func friendOriginDisplay(for friend: UserProfile) -> String? {
        guard let flag = friend.originFlag, let name = friend.originName else {
            return nil
        }
        return "\(flag) \(name)"
    }
}

private func tribeRow(_ tribe: ProfileTribe) -> some View {
    HStack(spacing: 12) {
        tribeImage(for: tribe)
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

@ViewBuilder
private func tribeImage(for tribe: ProfileTribe) -> some View {
    if let photoURL = tribe.photoURL {
        AsyncImage(url: photoURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Colors.secondaryText.opacity(0.3)
            }
        }
    } else if !tribe.imageName.isEmpty {
        Image(tribe.imageName)
            .resizable()
            .scaledToFill()
    } else {
        Colors.secondaryText.opacity(0.3)
    }
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

struct ProfileTribe: Identifiable {
    let id: UUID
    let imageName: String
    let name: String
    let status: String
    let photoURL: URL?

    init(id: UUID = UUID(), imageName: String, name: String, status: String, photoURL: URL? = nil) {
        self.id = id
        self.imageName = imageName
        self.name = name
        self.status = status
        self.photoURL = photoURL
    }
}

struct ProfileFriend: Identifiable {
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

private struct FriendRow: Decodable {
    let userID: UUID
    let friendID: UUID

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case friendID = "friend_id"
    }
}

private struct ProfileTribeJoinRow: Decodable {
    let tribeID: UUID

    enum CodingKeys: String, CodingKey {
        case tribeID = "tribe_id"
    }
}

private struct ProfileTribeRow: Decodable {
    let id: UUID
    let name: String
    let destination: String
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case destination
        case photoURL = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""

        if let photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURL) {
            photoURL = URL(string: photoURLString)
        } else {
            photoURL = nil
        }
    }
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
            ProfileTribe(imageName: "profile4", name: "Pacific Travelers", status: "Active"),
            ProfileTribe(imageName: "profile5", name: "Mountain Crew", status: "Planning")
        ]
    )
    .environmentObject(ProfileStore())
}
