//
//  ProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import Supabase

private let profileTribeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let profileTribeTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let profileTribeTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private enum ProfileTribeListCache {
    static var latestTribes: [ProfileTribe] = []
    static var tribesByUser: [UUID: [ProfileTribe]] = [:]

    static func cachedTribes(for userID: UUID?) -> [ProfileTribe] {
        guard let userID else { return latestTribes }
        return tribesByUser[userID] ?? latestTribes
    }

    static func update(_ tribes: [ProfileTribe], for userID: UUID) {
        tribesByUser[userID] = tribes
        latestTribes = tribes
    }
}

private enum ProfileTribeImageCache {
    static var images: [URL: Image] = [:]
}

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
    let trips: [ProfileTrip]
    let countries: [ProfileCountry]
    let tribes: [ProfileTribe]
    
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var joinedTribes: [ProfileTribe] = []
    @State private var isLoadingTribes = false
    @State private var tribeImageCache: [URL: Image] = ProfileTribeImageCache.images
    @State private var isCountrySheetPresented = false
    @State private var userCountries: [ProfileCountry] = []
    @State private var userCountryIDs: Set<String> = []
    @State private var isLoadingCountries = false
    @State private var pastTrips: [ProfileTrip] = []
    @State private var isLoadingPastTrips = false
    @State private var hasLoadedPastTrips = false
    @State private var userTripsCount: Int?
    @State private var isPastTripsSheetPresented = false
    @State private var isTribesSheetPresented = false
    @State private var isFriendsSheetPresented = false
    
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

    private var currentCountries: [ProfileCountry] {
        userCountries.isEmpty ? countries : userCountries
    }

    private var currentCountriesCount: Int {
        userCountries.isEmpty ? countriesCount : userCountries.count
    }

    private var currentTrips: [ProfileTrip] {
        hasLoadedPastTrips ? pastTrips : trips
    }

    private var currentTripsCount: Int {
        userTripsCount ?? tripsCount
    }

    private var worldPercent: Int {
        let totalCountries = CountryDatabase.all.count
        guard totalCountries > 0 else { return 0 }

        let visitedISOSet = Set(currentCountries.map { $0.isoCode.uppercased() })
        let visitedCount = CountryDatabase.all.filter { visitedISOSet.contains($0.isoCode.uppercased()) }.count

        return Int((Double(visitedCount) / Double(totalCountries)) * 100)
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
                        counterCard(title: "Trips", value: "\(currentTripsCount)")
                        counterCard(title: "Countries", value: "\(currentCountriesCount)")
                        counterCard(title: "World", value: "\(worldPercent)%")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Past Trips")
                                .font(.custom(Fonts.semibold, size: 18))
                                .foregroundStyle(Colors.primaryText)

                            Spacer()

                            Button { isPastTripsSheetPresented = true } label: {
                                SeeAllButton()
                            }
                        }

                        VStack(spacing: 12) {
                            if currentTrips.isEmpty {
                                Text("No past trips yet.")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.secondaryText)
                            } else {
                                let displayedTrips = Array(currentTrips.prefix(1))

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
                                TravelStatsView(countries: currentCountries) { country in
                                    Task {
                                        await deleteCountry(country)
                                    }
                                }
                            } label: {
                                Text("See More")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                        }

                        VStack(spacing: 12) {
                            let displayedCountries = Array(currentCountries.prefix(1))

                            if currentCountries.isEmpty {
                                Text("No countries yet.")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.secondaryText)
                            } else {
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
                            }

                            Button(action: { isCountrySheetPresented = true }) {
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
                            
                            Button { isTribesSheetPresented = true } label: {
                                SeeAllButton()
                            }
                        }
                        
                        if !displayedTribes.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(Array(displayedTribes.prefix(3))) { tribe in
                                    NavigationLink {
                                        TribesSocialView(
                                            imageURL: tribe.photoURL,
                                            title: tribe.name,
                                            location: tribe.status,
                                            flag: "",
                                            endDate: tribe.endDate,
                                            createdAt: tribe.createdAt,
                                            gender: tribe.gender,
                                            aboutText: tribe.aboutText,
                                            interests: tribe.interests,
                                            placeName: tribe.status,
                                            tribeID: tribe.id,
                                            createdBy: nil,
                                            createdByAvatarPath: nil,
                                            isCreator: supabase?.auth.currentUser?.id == tribe.ownerID,
                                            onDelete: nil,
                                            onBack: nil,
                                            initialHeaderImage: tribe.photoURL.flatMap { cachedTribeImage(for: $0) }
                                        )
                                    } label: {
                                        tribeRow(tribe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            Text("No tribes yet.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
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
                            
                            Button { isFriendsSheetPresented = true } label: {
                                SeeAllButton()
                            }
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
        .sheet(isPresented: $isCountrySheetPresented) {
            CountryPickerSheet(initialSelectedIDs: userCountryIDs) { selectedIDs in
                Task {
                    await saveCountries(selectedIDs)
                }
            }
        }
        .sheet(isPresented: $isPastTripsSheetPresented) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if currentTrips.isEmpty {
                            Text("No past trips yet.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                        } else {
                            ForEach(currentTrips) { trip in
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
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $isTribesSheetPresented) {
            NavigationStack {
                ZStack {
                    Colors.background
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if displayedTribes.isEmpty {
                                Text("No tribes yet.")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.secondaryText)
                            } else {
                                ForEach(displayedTribes) { tribe in
                                    NavigationLink {
                                        TribesSocialView(
                                            imageURL: tribe.photoURL,
                                            title: tribe.name,
                                            location: tribe.status,
                                            flag: "",
                                            endDate: tribe.endDate,
                                            createdAt: tribe.createdAt,
                                            gender: tribe.gender,
                                            aboutText: tribe.aboutText,
                                            interests: tribe.interests,
                                            placeName: tribe.status,
                                            tribeID: tribe.id,
                                            createdBy: nil,
                                            createdByAvatarPath: nil,
                                            isCreator: supabase?.auth.currentUser?.id == tribe.ownerID,
                                            onDelete: nil,
                                            onBack: nil,
                                            initialHeaderImage: tribe.photoURL.flatMap { cachedTribeImage(for: $0) }
                                        )
                                    } label: {
                                        tribeRow(tribe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $isFriendsSheetPresented) {
            NavigationStack {
                ZStack {
                    Colors.background
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if friends.isEmpty {
                                Text("No friends yet")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.secondaryText)
                            } else {
                                ForEach(friends) { friend in
                                    NavigationLink {
                                        OthersProfileView(userID: friend.id)
                                    } label: {
                                        friendCard(friend)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await loadFriends()
            await loadTribes()
            await loadPastTrips()
            await loadUserCountries()
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

        let cachedTribes = ProfileTribeListCache.cachedTribes(for: userID)
        if joinedTribes.isEmpty, !cachedTribes.isEmpty {
            joinedTribes = cachedTribes
        }

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
                ProfileTribeListCache.update([], for: userID)
                return
            }

            let tribeIDStrings = tribeIDs.map { $0.uuidString }
            let tribes: [ProfileTribeRow] = try await supabase
                .from("tribes")
                .select("id, owner_id, name, destination, photo_url, end_date, created_at, gender, description, interests")
                .in("id", values: tribeIDStrings)
                .execute()
                .value

            joinedTribes = tribes.map { tribe in
                ProfileTribe(
                    id: tribe.id,
                    ownerID: tribe.ownerID,
                    imageName: "",
                    name: tribe.name,
                    status: tribe.destination,
                    photoURL: tribe.photoURL,
                    endDate: tribe.endDate,
                    createdAt: tribe.createdAt,
                    gender: tribe.gender,
                    aboutText: tribe.aboutText,
                    interests: tribe.interests
                )
            }
            ProfileTribeListCache.update(joinedTribes, for: userID)
        } catch {
            return
        }
    }

    @MainActor
    private func loadPastTrips() async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id,
              !isLoadingPastTrips else { return }

        isLoadingPastTrips = true
        defer { isLoadingPastTrips = false }

        do {
            let fetchedTrips: [Trip] = try await supabase
                .from("mytrips")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("return_date", ascending: false)
                .execute()
                .value

            userTripsCount = fetchedTrips.count
            let startOfToday = Calendar.current.startOfDay(for: Date())
            pastTrips = fetchedTrips
                .filter { $0.returnDate < startOfToday }
                .map { profileTrip(from: $0) }
            hasLoadedPastTrips = true
        } catch {
            return
        }
    }

    @MainActor
    private func loadUserCountries() async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id,
              !isLoadingCountries else { return }

        isLoadingCountries = true
        defer { isLoadingCountries = false }

        do {
            let rows: [UserCountryRow] = try await supabase
                .from("user_countries")
                .select("id, country_iso")
                .eq("id", value: userID.uuidString)
                .execute()
                .value

            let isoCodes = rows.map { $0.countryISO.uppercased() }
            userCountryIDs = Set(isoCodes)
            userCountries = isoCodes.compactMap { isoCode in
                guard let country = CountryDatabase.all.first(where: { $0.id == isoCode }) else { return nil }
                return ProfileCountry(
                    flag: country.flag,
                    name: country.name,
                    isoCode: country.isoCode,
                    note: "",
                    imageQuery: country.name
                )
            }
        } catch {
            return
        }
    }

    @MainActor
    private func saveCountries(_ selectedIDs: Set<String>) async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id
        else { return }

        let newCountryIDs = selectedIDs.subtracting(userCountryIDs)
        let removedCountryIDs = userCountryIDs.subtracting(selectedIDs)
        guard !newCountryIDs.isEmpty || !removedCountryIDs.isEmpty else { return }

        do {
            if !newCountryIDs.isEmpty {
                let payload = newCountryIDs.map { UserCountryInsert(id: userID, countryISO: $0) }
                try await supabase
                    .from("user_countries")
                    .insert(payload)
                    .execute()
            }
            if !removedCountryIDs.isEmpty {
                try await supabase
                    .from("user_countries")
                    .delete()
                    .eq("id", value: userID.uuidString)
                    .in("country_iso", values: Array(removedCountryIDs))
                    .execute()
            }
            await loadUserCountries()
        } catch {
            return
        }
    }

    @MainActor
    private func deleteCountry(_ country: ProfileCountry) async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id
        else { return }

        let isoCode = country.isoCode.uppercased()

        do {
            try await supabase
                .from("user_countries")
                .delete()
                .eq("id", value: userID.uuidString)
                .eq("country_iso", value: isoCode)
                .execute()

            let updatedCountries = currentCountries.filter {
                $0.isoCode.uppercased() != isoCode
            }
            userCountries = updatedCountries
            userCountryIDs = Set(updatedCountries.map { $0.isoCode.uppercased() })
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

    private func profileTrip(from trip: Trip) -> ProfileTrip {
        ProfileTrip(
            flag: tripFlag(for: trip),
            location: tripLocation(for: trip),
            dates: tripDateRange(for: trip),
            imageQuery: tripImageQuery(for: trip)
        )
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
        return start == end ? start : "\(start) - \(end)"
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

    private func tribeRow(_ tribe: ProfileTribe) -> some View {
        HStack(spacing: 12) {
            tribeImage(for: tribe)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(tribe.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                Text(tribe.status)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .lineLimit(1)
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
            if let cachedImage = cachedTribeImage(for: photoURL) {
                cachedImage
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                if tribeImageCache[photoURL] == nil {
                                    cacheTribeImage(image, for: photoURL)
                                }
                            }
                    case .empty:
                        Colors.card
                    default:
                        Colors.card
                    }
                }
            }
        } else if !tribe.imageName.isEmpty {
            Image(tribe.imageName)
                .resizable()
                .scaledToFill()
        } else {
            Colors.card
        }
    }

    private func cachedTribeImage(for url: URL) -> Image? {
        tribeImageCache[url]
    }

    private func cacheTribeImage(_ image: Image, for url: URL) {
        tribeImageCache[url] = image
        ProfileTribeImageCache.images[url] = image
    }
}

private struct CountryPickerSheet: View {
    let onSave: (Set<String>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCountryIDs: Set<String>
    
    private var filteredCountries: [Country] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty {
            return CountryDatabase.all
        }
        return CountryDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    init(initialSelectedIDs: Set<String>, onSave: @escaping (Set<String>) -> Void) {
        self.onSave = onSave
        _selectedCountryIDs = State(initialValue: initialSelectedIDs)
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Save") {
                        onSave(selectedCountryIDs)
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField(
                        "",
                        text: $searchText,
                        prompt: Text("Search country")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    )
                    .font(.travelBody)
                    .foregroundStyle(Colors.primaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .cornerRadius(12)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCountries) { country in
                            let isSelected = selectedCountryIDs.contains(country.id)
                            
                            Button {
                                if isSelected {
                                    selectedCountryIDs.remove(country.id)
                                } else {
                                    selectedCountryIDs.insert(country.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(country.flag)
                                        .font(.travelTitle)
                                    Text(country.name)
                                        .font(.travelBody)
                                        .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
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
    let ownerID: UUID
    let imageName: String
    let name: String
    let status: String
    let photoURL: URL?
    let endDate: Date
    let createdAt: Date
    let gender: String
    let aboutText: String?
    let interests: [String]

    init(
        id: UUID = UUID(),
        ownerID: UUID = UUID(),
        imageName: String,
        name: String,
        status: String,
        photoURL: URL? = nil,
        endDate: Date = Date(),
        createdAt: Date = Date(),
        gender: String = "",
        aboutText: String? = nil,
        interests: [String] = []
    ) {
        self.id = id
        self.ownerID = ownerID
        self.imageName = imageName
        self.name = name
        self.status = status
        self.photoURL = photoURL
        self.endDate = endDate
        self.createdAt = createdAt
        self.gender = gender
        self.aboutText = aboutText
        self.interests = interests
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
    let isoCode: String
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

private struct UserCountryRow: Decodable {
    let id: UUID
    let countryISO: String

    enum CodingKeys: String, CodingKey {
        case id
        case countryISO = "country_iso"
    }
}

private struct UserCountryInsert: Encodable {
    let id: UUID
    let countryISO: String

    enum CodingKeys: String, CodingKey {
        case id
        case countryISO = "country_iso"
    }
}

private struct ProfileTribeRow: Decodable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let destination: String
    let photoURL: URL?
    let endDate: Date
    let createdAt: Date
    let gender: String
    let aboutText: String?
    let interests: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case destination
        case photoURL = "photo_url"
        case endDate = "end_date"
        case createdAt = "created_at"
        case gender
        case aboutText = "description"
        case interests
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decode(UUID.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""
        gender = try container.decode(String.self, forKey: .gender)
        aboutText = try container.decodeIfPresent(String.self, forKey: .aboutText)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []

        if let photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURL) {
            photoURL = URL(string: photoURLString)
        } else {
            photoURL = nil
        }

        let endDateString = try container.decode(String.self, forKey: .endDate)
        guard let decodedEndDate = profileTribeDateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.endDate], debugDescription: "Invalid end date format")
            )
        }
        endDate = decodedEndDate

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let decodedCreatedAt = profileTribeTimestampFormatterWithFractional.date(from: createdAtString)
            ?? profileTribeTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = decodedCreatedAt
    }
}
