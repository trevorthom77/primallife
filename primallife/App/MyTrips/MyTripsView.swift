import SwiftUI
import Combine
import Supabase

private let myTripsDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let myTripsTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let myTripsTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

struct Trip: Decodable, Identifiable {
    let id: UUID
    let userID: UUID
    let destination: String
    let checkIn: Date
    let returnDate: Date
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case destination
        case checkIn = "check_in"
        case returnDate = "return_date"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        destination = try container.decode(String.self, forKey: .destination)

        let checkInString = try container.decode(String.self, forKey: .checkIn)
        guard let checkInDate = myTripsDateFormatter.date(from: checkInString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.checkIn], debugDescription: "Invalid check-in date format")
            )
        }
        checkIn = checkInDate

        let returnDateString = try container.decode(String.self, forKey: .returnDate)
        guard let decodedReturnDate = myTripsDateFormatter.date(from: returnDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.returnDate], debugDescription: "Invalid return date format")
            )
        }
        returnDate = decodedReturnDate
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

struct NewTrip: Encodable {
    let userID: UUID
    let destination: String
    let checkIn: Date
    let returnDate: Date
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case destination
        case checkIn = "check_in"
        case returnDate = "return_date"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(destination, forKey: .destination)
        try container.encode(myTripsDateFormatter.string(from: checkIn), forKey: .checkIn)
        try container.encode(myTripsDateFormatter.string(from: returnDate), forKey: .returnDate)
    }
}

struct Recommendation: Decodable, Identifiable {
    let id: UUID
    let creatorID: UUID
    let destination: String
    let name: String
    let note: String
    let rating: Double
    let photoURL: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case creatorID = "creator_id"
        case destination
        case name
        case note
        case rating
        case photoURL = "photo_url"
        case createdAt = "created_at"
    }
}

struct NewRecommendation: Encodable {
    let creatorID: UUID
    let destination: String
    let name: String
    let note: String
    let rating: Double
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case creatorID = "creator_id"
        case destination
        case name
        case note
        case rating
        case photoURL = "photo_url"
    }
}

struct Tribe: Decodable, Identifiable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let description: String?
    let endDate: Date
    let createdAt: Date
    let gender: String
    let privacy: String
    let interests: [String]
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case description
        case endDate = "end_date"
        case createdAt = "created_at"
        case gender
        case privacy
        case interests
        case photoURL = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decode(UUID.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        let endDateString = try container.decode(String.self, forKey: .endDate)
        guard let decodedEndDate = myTripsDateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.endDate], debugDescription: "Invalid end date format")
            )
        }
        endDate = decodedEndDate

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let decodedCreatedAt = myTripsTimestampFormatterWithFractional.date(from: createdAtString)
            ?? myTripsTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = decodedCreatedAt

        gender = try container.decode(String.self, forKey: .gender)
        privacy = try container.decode(String.self, forKey: .privacy)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []

        if let photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURL) {
            photoURL = URL(string: photoURLString)
        } else {
            photoURL = nil
        }
    }
}

@MainActor
final class MyTripsViewModel: ObservableObject {
    private struct TribeCreator: Decodable {
        let id: String
        let fullName: String
        let avatarPath: String?
        let origin: String?
        let birthday: String?

        enum CodingKeys: String, CodingKey {
            case id
            case fullName = "full_name"
            case avatarPath = "avatar_url"
            case origin
            case birthday
        }
    }

    private struct TribeMemberCountRow: Decodable {
        let tribeID: UUID

        enum CodingKeys: String, CodingKey {
            case tribeID = "tribe_id"
        }
    }

    @Published var trips: [Trip] = []
    @Published var error: String?
    @Published var tribesByTrip: [UUID: [Tribe]] = [:]
    @Published var travelersByTrip: [UUID: [UUID]] = [:]
    @Published var recommendationsByDestination: [String: [Recommendation]] = [:]
    @Published private(set) var loadingTribeTripIDs: Set<UUID> = []
    @Published private(set) var loadingTravelerTripIDs: Set<UUID> = []
    @Published private(set) var loadingRecommendationDestinations: Set<String> = []
    @Published private(set) var tribeMemberCounts: [UUID: Int] = [:]
    @Published private var tribeCreatorsByID: [String: TribeCreator] = [:]
    private var pendingTripKeys: Set<String> = []

    func loadTrips(supabase: SupabaseClient?) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }

        do {
            let fetchedTrips: [Trip] = try await supabase
                .from("mytrips")
                .select()
                .eq("user_id", value: "\(userID)")
                .order("created_at", ascending: false)
                .execute()
                .value

            let startOfToday = Calendar.current.startOfDay(for: Date())
            trips = fetchedTrips.filter { $0.returnDate >= startOfToday }
            error = nil
        } catch {
            self.error = "Unable to load trips."
        }
    }

    func addTrip(destination: String, checkIn: Date, returnDate: Date, supabase: SupabaseClient?) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let tripKey = pendingTripKey(destination: destination, checkIn: checkIn, returnDate: returnDate)
        if pendingTripKeys.contains(tripKey)
            || hasOverlappingTrip(destination: destination, checkIn: checkIn, returnDate: returnDate) {
            error = "You already added this trip."
            return
        }
        pendingTripKeys.insert(tripKey)
        defer { pendingTripKeys.remove(tripKey) }

        let payload = NewTrip(
            userID: userID,
            destination: destination,
            checkIn: checkIn,
            returnDate: returnDate
        )

        do {
            try await supabase
                .from("mytrips")
                .insert(payload)
                .execute()

            await loadTrips(supabase: supabase)
        } catch {
            self.error = "Unable to add trip."
        }
    }

    func deleteTrip(tripID: UUID, supabase: SupabaseClient?) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }

        do {
            try await supabase
                .from("mytrips")
                .delete()
                .eq("id", value: "\(tripID)")
                .eq("user_id", value: "\(userID)")
                .execute()

            await loadTrips(supabase: supabase)
        } catch {
            self.error = "Unable to delete trip."
        }
    }

    func loadTribes(for trip: Trip, supabase: SupabaseClient?) async {
        guard let supabase, !loadingTribeTripIDs.contains(trip.id) else { return }

        loadingTribeTripIDs.insert(trip.id)

        do {
            let fetchedTribes: [Tribe] = try await supabase
                .from("tribes")
                .select()
                .eq("destination", value: trip.destination)
                .execute()
                .value

            tribesByTrip[trip.id] = fetchedTribes
            await loadCreators(for: fetchedTribes, supabase: supabase)
            await loadMemberCounts(for: fetchedTribes, supabase: supabase)
        } catch {
            tribesByTrip[trip.id] = []
        }

        loadingTribeTripIDs.remove(trip.id)
    }

    func loadTravelers(for trip: Trip, supabase: SupabaseClient?) async {
        guard let supabase, !loadingTravelerTripIDs.contains(trip.id) else { return }

        loadingTravelerTripIDs.insert(trip.id)

        struct TripTraveler: Decodable {
            let userID: UUID

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
            }
        }

        do {
            let startOfToday = Calendar.current.startOfDay(for: Date())
            let startOfTodayString = myTripsDateFormatter.string(from: startOfToday)
            let fetchedTravelers: [TripTraveler] = try await supabase
                .from("mytrips")
                .select("user_id")
                .eq("destination", value: trip.destination)
                .gte("return_date", value: startOfTodayString)
                .execute()
                .value

            let uniqueUserIDs = Array(Set(fetchedTravelers.map { $0.userID }))
            travelersByTrip[trip.id] = uniqueUserIDs
            await loadCreators(for: uniqueUserIDs, supabase: supabase)
        } catch {
            travelersByTrip[trip.id] = []
        }

        loadingTravelerTripIDs.remove(trip.id)
    }

    func loadRecommendations(for destination: String, supabase: SupabaseClient?) async {
        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let supabase,
              !trimmedDestination.isEmpty,
              !loadingRecommendationDestinations.contains(trimmedDestination) else { return }

        loadingRecommendationDestinations.insert(trimmedDestination)
        defer { loadingRecommendationDestinations.remove(trimmedDestination) }

        do {
            let fetchedRecommendations: [Recommendation] = try await supabase
                .from("recommendations")
                .select()
                .eq("destination", value: trimmedDestination)
                .order("created_at", ascending: false)
                .execute()
                .value

            recommendationsByDestination[trimmedDestination] = fetchedRecommendations
            let creatorIDs = Array(Set(fetchedRecommendations.map(\.creatorID)))
            if !creatorIDs.isEmpty {
                await loadCreators(for: creatorIDs, supabase: supabase)
            }
        } catch {
            recommendationsByDestination[trimmedDestination] = []
        }
    }

    func addRecommendation(
        destination: String,
        name: String,
        note: String,
        rating: Double,
        photoData: Data?,
        supabase: SupabaseClient?
    ) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty, !trimmedName.isEmpty, !trimmedNote.isEmpty else { return }
        guard (1...10).contains(rating) else { return }

        do {
            var photoPath: String?
            if let photoData, !photoData.isEmpty {
                let path = "\(userID)/recommendations/\(UUID().uuidString).jpg"
                try await supabase.storage
                    .from("recommendation-photos")
                    .upload(
                        path,
                        data: photoData,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                photoPath = path
            }

            let payload = NewRecommendation(
                creatorID: userID,
                destination: trimmedDestination,
                name: trimmedName,
                note: trimmedNote,
                rating: rating,
                photoURL: photoPath
            )

            try await supabase
                .from("recommendations")
                .insert(payload)
                .execute()

            await loadRecommendations(for: trimmedDestination, supabase: supabase)
        } catch {
            self.error = "Unable to create recommendation."
        }
    }

    func creatorName(for ownerID: UUID) -> String? {
        tribeCreatorsByID[ownerID.uuidString.lowercased()]?.fullName
    }

    func creatorAvatarPath(for ownerID: UUID) -> String? {
        tribeCreatorsByID[ownerID.uuidString.lowercased()]?.avatarPath
    }

    func creatorAvatarURL(for ownerID: UUID, supabase: SupabaseClient?) -> URL? {
        guard let supabase, let avatarPath = creatorAvatarPath(for: ownerID) else { return nil }

        do {
            return try supabase.storage
                .from("profile-photos")
                .getPublicURL(path: avatarPath)
        } catch {
            return nil
        }
    }

    func creatorOriginFlag(for userID: UUID) -> String? {
        guard let origin = tribeCreatorsByID[userID.uuidString.lowercased()]?.origin,
              !origin.isEmpty else {
            return nil
        }
        return CountryDatabase.all.first(where: { $0.id == origin })?.flag
    }

    func creatorOriginName(for userID: UUID) -> String? {
        guard let origin = tribeCreatorsByID[userID.uuidString.lowercased()]?.origin,
              !origin.isEmpty else {
            return nil
        }
        return CountryDatabase.all.first(where: { $0.id == origin })?.name
    }

    func memberCount(for tribeID: UUID) -> Int {
        tribeMemberCounts[tribeID] ?? 0
    }

    func creatorAge(for userID: UUID) -> Int? {
        guard let birthdayString = tribeCreatorsByID[userID.uuidString.lowercased()]?.birthday,
              !birthdayString.isEmpty else {
            return nil
        }

        let birthDate = myTripsTimestampFormatterWithFractional.date(from: birthdayString)
            ?? myTripsTimestampFormatter.date(from: birthdayString)
            ?? myTripsDateFormatter.date(from: birthdayString)
        guard let birthDate else { return nil }

        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    private func loadCreators(for tribes: [Tribe], supabase: SupabaseClient) async {
        await loadCreators(for: tribes.map { $0.ownerID }, supabase: supabase)
    }

    private func loadMemberCounts(for tribes: [Tribe], supabase: SupabaseClient) async {
        let tribeIDs = Array(Set(tribes.map { $0.id }))
        guard !tribeIDs.isEmpty else { return }

        do {
            let rows: [TribeMemberCountRow] = try await supabase
                .from("tribes_join")
                .select("tribe_id")
                .in("tribe_id", values: tribeIDs.map { $0.uuidString })
                .execute()
                .value

            var counts: [UUID: Int] = [:]
            for row in rows {
                counts[row.tribeID, default: 0] += 1
            }
            for tribeID in tribeIDs where counts[tribeID] == nil {
                counts[tribeID] = 0
            }
            tribeMemberCounts.merge(counts) { _, new in new }
        } catch {
            for tribeID in tribeIDs where tribeMemberCounts[tribeID] == nil {
                tribeMemberCounts[tribeID] = 0
            }
        }
    }

    private func loadCreators(for userIDs: [UUID], supabase: SupabaseClient) async {
        let normalizedIDs = Set(userIDs.map { $0.uuidString.lowercased() })
        let missingIDs = normalizedIDs.filter { tribeCreatorsByID[$0] == nil }
        guard !missingIDs.isEmpty else { return }

        do {
            let creators: [TribeCreator] = try await supabase
                .from("onboarding")
                .select("id, full_name, avatar_url, origin, birthday")
                .in("id", values: Array(missingIDs))
                .execute()
                .value

            let lookup = Dictionary(uniqueKeysWithValues: creators.map { ($0.id.lowercased(), $0) })
            tribeCreatorsByID.merge(lookup) { _, new in new }
        } catch {
            return
        }
    }

    func isLoadingTribes(tripID: UUID) -> Bool {
        loadingTribeTripIDs.contains(tripID)
    }

    func isLoadingTravelers(tripID: UUID) -> Bool {
        loadingTravelerTripIDs.contains(tripID)
    }

    private func normalizedDestination(_ destination: String) -> String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func pendingTripKey(destination: String, checkIn: Date, returnDate: Date) -> String {
        let normalized = normalizedDestination(destination)
        let checkInString = myTripsDateFormatter.string(from: checkIn)
        let returnString = myTripsDateFormatter.string(from: returnDate)
        return "\(normalized)|\(checkInString)|\(returnString)"
    }

    private func hasOverlappingTrip(destination: String, checkIn: Date, returnDate: Date) -> Bool {
        let normalized = normalizedDestination(destination)
        let normalizedCheckIn = Calendar.current.startOfDay(for: checkIn)
        let normalizedReturn = Calendar.current.startOfDay(for: returnDate)
        return trips.contains { trip in
            normalizedDestination(trip.destination) == normalized
                && normalizedCheckIn <= trip.returnDate
                && normalizedReturn >= trip.checkIn
        }
    }
}

struct MyTripsView: View {
    @Environment(\.supabaseClient) var supabase
    @StateObject private var viewModel = MyTripsViewModel()
    @State private var tripImageDetails: [UUID: UnsplashImageDetails] = [:]
    @State private var selectedTripForTribe: Trip?
    @State private var isShowingTrips = false
    @State private var isShowingUpcomingTripsSheet = false
    @State private var isShowingTribeTrips = false
    @State private var selectedTripIndex = 0
    @State private var tribeImageCache: [UUID: Image] = [:]
    @State private var tribeImageURLCache: [UUID: URL] = [:]
    @State private var recommendationAvatarCache: [UUID: Image] = [:]
    @State private var recommendationAvatarURLCache: [UUID: URL] = [:]
    
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
                            if !viewModel.trips.isEmpty {
                                HStack {
                                    Text("Upcoming Trips")
                                        .font(.travelTitle)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Button {
                                        isShowingUpcomingTripsSheet = true
                                    } label: {
                                        SeeAllButton()
                                    }
                                }
                                
                                TabView(selection: $selectedTripIndex) {
                                    ForEach(Array(displayedTrips.enumerated()), id: \.element.id) { index, trip in
                                        HStack(spacing: 0) {
                                            NavigationLink {
                                                UpcomingTripsFullView(
                                                    trip: trip,
                                                    prefetchedDetails: tripImageDetails[trip.id],
                                                    tribeImageCache: $tribeImageCache,
                                                    tribeImageURLCache: $tribeImageURLCache
                                                )
                                            } label: {
                                                TravelCard(
                                                    flag: "",
                                                    location: trip.destination,
                                                    dates: tripDateRange(for: trip),
                                                    imageQuery: tripImageQuery(for: trip),
                                                    participantCount: travelerCount(for: trip),
                                                    showsAttribution: true,
                                                    allowsHitTesting: true,
                                                    prefetchedDetails: tripImageDetails[trip.id]
                                                )
                                            }
                                            .buttonStyle(.plain)

                                            Spacer()
                                        }
                                        .tag(index)
                                    }
                                }
                                .frame(height: 180)
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .sensoryFeedback(.impact(weight: .medium), trigger: selectedTripIndex)

                                if displayedTrips.count > 1 {
                                    HStack(spacing: 18) {
                                        ForEach(0..<displayedTrips.count, id: \.self) { index in
                                            Image("airplane")
                                                .renderingMode(.template)
                                                .foregroundStyle(
                                                    selectedTripIndex == index ? Colors.accent : Colors.secondaryText
                                                )
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image("australia")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 220, height: 220)
                                        .padding(.bottom, 4)
                                    Text("No upcoming trips yet")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Text("Add your next destination to see it here.")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                    
                                    Button {
                                        isShowingTrips = true
                                    } label: {
                                        Text("Add Trip")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.tertiaryText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Colors.accent)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            }

                            if let trip = selectedTrip {
                                HStack {
                                    Text("\(selectedTripTitle) Tribes")
                                        .font(.travelTitle)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    NavigationLink {
                                        UpcomingTripsFullView(
                                            trip: trip,
                                            prefetchedDetails: tripImageDetails[trip.id],
                                            tribeImageCache: $tribeImageCache,
                                            tribeImageURLCache: $tribeImageURLCache,
                                            startOnTribesTab: true
                                        )
                                    } label: {
                                        SeeAllButton()
                                    }
                                }
                                .padding(.top, 16)
                                
                                if let tribes = tribesForSelectedTrip {
                                    if tribes.isEmpty {
                                        Text("No tribes yet.")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                            .padding(.vertical, 4)
                                    } else {
                                        ForEach(tribes.prefix(2)) { tribe in
                                            NavigationLink {
                                                TribesSocialView(
                                                    imageURL: tribe.photoURL,
                                                    title: tribe.name,
                                                    location: selectedTripDestination,
                                                    flag: "",
                                                    endDate: tribe.endDate,
                                                    createdAt: tribe.createdAt,
                                                    gender: tribe.gender,
                                                    aboutText: tribe.description,
                                                    interests: tribe.interests,
                                                    placeName: selectedTripDestination,
                                                    tribeID: tribe.id,
                                                    createdBy: viewModel.creatorName(for: tribe.ownerID),
                                                    createdByAvatarPath: viewModel.creatorAvatarPath(for: tribe.ownerID),
                                                    isCreator: supabase?.auth.currentUser?.id == tribe.ownerID,
                                                    onDelete: {
                                                        Task {
                                                            await loadTribesForSelectedTrip(force: true)
                                                        }
                                                    },
                                                    initialHeaderImage: cachedTribeImage(for: tribe)
                                            )
                                        } label: {
                                                VStack(alignment: .leading, spacing: 12) {
                                                    HStack(spacing: 12) {
                                                        tribeImage(for: tribe)
                                                            .frame(width: 64, height: 64)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            Text(tribe.name)
                                                                .font(.travelDetail)
                                                                .foregroundStyle(Colors.primaryText)
                                                                .lineLimit(1)
                                                                .truncationMode(.tail)
                                                            
                                                            Text(selectedTripDestination)
                                                                .font(.travelDetail)
                                                                .foregroundStyle(Colors.secondaryText)
                                                                .lineLimit(1)
                                                                .truncationMode(.tail)
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
                                                                
                                                                Text("\(viewModel.memberCount(for: tribe.id))+")
                                                                    .font(.custom(Fonts.semibold, size: 12))
                                                                    .foregroundStyle(Colors.primaryText)
                                                            }
                                                        }
                                                    }
                                                    .padding(12)
                                                    .background(Colors.card)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                } else if isLoadingTribesForSelectedTrip {
                                    ProgressView()
                                        .tint(Colors.accent)
                                        .padding(.vertical, 4)
                                }

                                Button(action: {
                                    if let trip = selectedTrip {
                                        selectedTripForTribe = trip
                                        isShowingTribeTrips = true
                                    }
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

                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Recommendations")
                                            .font(.travelTitle)
                                            .foregroundStyle(Colors.primaryText)

                                        Spacer()

                                        Button { } label: {
                                            SeeAllButton()
                                        }
                                    }

                                    if let recommendations = recommendationsForSelectedTrip {
                                        ForEach(recommendations) { recommendation in
                                            let ratingText = String(format: "%.1f", recommendation.rating)

                                            HStack(spacing: 12) {
                                                recommendationAvatar(for: recommendation)

                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(recommendation.name)
                                                        .font(.travelDetail)
                                                        .foregroundStyle(Colors.primaryText)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)

                                                    HStack(spacing: 8) {
                                                        Text(recommendation.destination)
                                                            .font(.travelDetail)
                                                            .foregroundStyle(Colors.secondaryText)
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                    }
                                                }

                                                Spacer()

                                                Text(ratingText)
                                                    .font(.travelDetail)
                                                    .foregroundStyle(Colors.tertiaryText)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(recommendationRatingColor(ratingText))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88, alignment: .leading)
                                            .background(Colors.card)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                    }
                                }

                                NavigationLink {
                                    RecommendationCreationView(
                                        trip: trip,
                                        imageDetails: tripImageDetails[trip.id],
                                        supabase: supabase,
                                        viewModel: viewModel
                                    )
                                } label: {
                                    Text("Add Recommendation")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.tertiaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Colors.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)

                                HStack {
                                    Text("Travelers going")
                                        .font(.travelTitle)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    NavigationLink {
                                        UpcomingTripsFullView(
                                            trip: trip,
                                            prefetchedDetails: tripImageDetails[trip.id],
                                            tribeImageCache: $tribeImageCache,
                                            tribeImageURLCache: $tribeImageURLCache
                                        )
                                    } label: {
                                        SeeAllButton()
                                    }
                                }
                                .padding(.top, 16)

                                if let travelers = travelersForSelectedTrip {
                                    let currentUserID = supabase?.auth.currentUser?.id
                                    let visibleTravelers = travelers.filter { $0 != currentUserID }
                                    if visibleTravelers.isEmpty {
                                        Text("No travelers yet.")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                            .padding(.vertical, 4)
                                    } else {
                                        ForEach(visibleTravelers.prefix(3), id: \.self) { travelerID in
                                            if let name = viewModel.creatorName(for: travelerID) {
                                                NavigationLink {
                                                    OthersProfileView(userID: travelerID)
                                                } label: {
                                                    HStack(spacing: 12) {
                                                        travelerAvatar(for: travelerID)

                                                        VStack(alignment: .leading, spacing: 6) {
                                                            HStack(spacing: 8) {
                                                                Text(name)
                                                                    .font(.travelDetail)
                                                                    .foregroundStyle(Colors.primaryText)

                                                                if let age = viewModel.creatorAge(for: travelerID) {
                                                                    Text("\(age)")
                                                                        .font(.travelDetail)
                                                                        .foregroundStyle(Colors.secondaryText)
                                                                }
                                                            }

                                                            let originFlag = viewModel.creatorOriginFlag(for: travelerID)
                                                            let originName = viewModel.creatorOriginName(for: travelerID)
                                                            if originFlag != nil || originName != nil {
                                                                HStack(spacing: 8) {
                                                                    if let flag = originFlag {
                                                                        Text(flag)
                                                                            .font(.travelDetail)
                                                                            .foregroundStyle(Colors.primaryText)
                                                                    }

                                                                    if let countryName = originName {
                                                                        Text(countryName)
                                                                            .font(.travelDetail)
                                                                            .foregroundStyle(Colors.secondaryText)
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        Spacer()
                                                    }
                                                    .padding()
                                                    .background(Colors.card)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                } else if isLoadingTravelersForSelectedTrip {
                                    ProgressView()
                                        .tint(Colors.accent)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.vertical, 16)
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
                TripsView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $isShowingTribeTrips) {
                if let trip = selectedTripForTribe {
                    TribeTripsView(
                        trip: trip,
                        imageDetails: tripImageDetails[trip.id],
                        onFinish: {
                            isShowingTribeTrips = false
                        }
                    )
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $isShowingUpcomingTripsSheet) {
                UpcomingTripsSheetView(
                    trips: viewModel.trips,
                    tripImageDetails: tripImageDetails,
                    onDeleteTrip: { trip in
                        Task {
                            await viewModel.deleteTrip(tripID: trip.id, supabase: supabase)
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadTrips(supabase: supabase)
            await prefetchTripImages()
            await loadTribesForSelectedTrip(force: true)
            await loadTravelersForSelectedTrip(force: true)
            await loadRecommendationsForSelectedTrip(force: true)
        }
        .task(id: viewModel.trips.count) {
            clampSelectedTripIndex()
            await prefetchTripImages()
            await loadTribesForSelectedTrip(force: true)
            await loadTravelersForSelectedTrip(force: true)
            await loadRecommendationsForSelectedTrip(force: true)
        }
        .task(id: selectedTripIndex) {
            await loadTribesForSelectedTrip()
            await loadTravelersForSelectedTrip()
            await loadRecommendationsForSelectedTrip()
        }
        .onChange(of: isShowingTribeTrips) { _, newValue in
            if !newValue {
                Task {
                    await loadTribesForSelectedTrip(force: true)
                }
            }
        }
        .onAppear {
            Task {
                await loadTribesForSelectedTrip(force: true)
                await loadTravelersForSelectedTrip(force: true)
            }
        }
    }
    
    private func prefetchTripImages() async {
        for trip in viewModel.trips where tripImageDetails[trip.id] == nil {
            let query = tripImageQuery(for: trip)
            if let details = await UnsplashService.fetchImageDetails(for: query) {
                await cacheImageIfNeeded(from: details.url)
                await MainActor.run {
                    tripImageDetails[trip.id] = details
                }
            }
        }
    }
    
    private func cacheImageIfNeeded(from url: URL) async {
        let request = URLRequest(url: url)
        if URLCache.shared.cachedResponse(for: request) != nil { return }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let cached = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cached, for: request)
        } catch { }
    }

    @MainActor
    private func loadTribesForSelectedTrip(force: Bool = false) async {
        guard let trip = selectedTrip else { return }
        if viewModel.isLoadingTribes(tripID: trip.id) { return }
        if !force, viewModel.tribesByTrip[trip.id] != nil { return }
        await viewModel.loadTribes(for: trip, supabase: supabase)
    }

    @MainActor
    private func loadTravelersForSelectedTrip(force: Bool = false) async {
        guard let trip = selectedTrip else { return }
        if viewModel.isLoadingTravelers(tripID: trip.id) { return }
        if !force, viewModel.travelersByTrip[trip.id] != nil { return }
        await viewModel.loadTravelers(for: trip, supabase: supabase)
    }

    @MainActor
    private func loadRecommendationsForSelectedTrip(force: Bool = false) async {
        guard let trip = selectedTrip else { return }
        let trimmedDestination = trip.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty else { return }
        if !force, viewModel.recommendationsByDestination[trimmedDestination] != nil { return }
        await viewModel.loadRecommendations(for: trimmedDestination, supabase: supabase)
    }

    private func clampSelectedTripIndex() {
        let maxIndex = max(0, min(viewModel.trips.count, 3) - 1)
        if selectedTripIndex > maxIndex {
            selectedTripIndex = maxIndex
        }
    }

    private var displayedTrips: [Trip] {
        Array(viewModel.trips.prefix(3))
    }
    
    private var selectedTrip: Trip? {
        guard displayedTrips.indices.contains(selectedTripIndex) else { return nil }
        return displayedTrips[selectedTripIndex]
    }

    private var tribesForSelectedTrip: [Tribe]? {
        guard let trip = selectedTrip else { return nil }
        return viewModel.tribesByTrip[trip.id]
    }

    private var travelersForSelectedTrip: [UUID]? {
        guard let trip = selectedTrip else { return nil }
        return viewModel.travelersByTrip[trip.id]
    }

    private var recommendationsForSelectedTrip: [Recommendation]? {
        guard let trip = selectedTrip else { return nil }
        let trimmedDestination = trip.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty else { return nil }
        return viewModel.recommendationsByDestination[trimmedDestination]
    }

    private func travelerCount(for trip: Trip) -> Int {
        let travelers = viewModel.travelersByTrip[trip.id] ?? []
        if let currentUserID = supabase?.auth.currentUser?.id {
            return travelers.filter { $0 != currentUserID }.count
        }
        return travelers.count
    }

    private var isLoadingTribesForSelectedTrip: Bool {
        guard let trip = selectedTrip else { return false }
        return viewModel.isLoadingTribes(tripID: trip.id)
    }

    private var isLoadingTravelersForSelectedTrip: Bool {
        guard let trip = selectedTrip else { return false }
        return viewModel.isLoadingTravelers(tripID: trip.id)
    }

    @ViewBuilder
    private func travelerAvatar(for travelerID: UUID) -> some View {
        let avatarURL = viewModel.creatorAvatarURL(for: travelerID, supabase: supabase)

        Group {
            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Colors.card, lineWidth: 3)
        }
    }

    @ViewBuilder
    private func recommendationAvatar(for recommendation: Recommendation) -> some View {
        let avatarURL = viewModel.creatorAvatarURL(for: recommendation.creatorID, supabase: supabase)

        Group {
            if let cachedImage = cachedRecommendationAvatar(for: recommendation.creatorID, avatarURL: avatarURL) {
                cachedImage
                    .resizable()
                    .scaledToFill()
            } else if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                recommendationAvatarCache[recommendation.creatorID] = image
                                recommendationAvatarURLCache[recommendation.creatorID] = avatarURL
                            }
                    } else {
                        Colors.secondaryText.opacity(0.3)
                    }
                }
            } else {
                Colors.secondaryText.opacity(0.3)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Colors.card, lineWidth: 3)
        }
    }

    private func cachedRecommendationAvatar(for creatorID: UUID, avatarURL: URL?) -> Image? {
        guard let cachedImage = recommendationAvatarCache[creatorID],
              recommendationAvatarURLCache[creatorID] == avatarURL else {
            return nil
        }
        return cachedImage
    }

    private func recommendationPhotoURL(for recommendation: Recommendation) -> URL? {
        guard let photoPath = recommendation.photoURL else { return nil }
        if let url = URL(string: photoPath), url.scheme != nil {
            return url
        }
        guard let supabase else { return nil }
        do {
            return try supabase.storage
                .from("recommendation-photos")
                .getPublicURL(path: photoPath)
        } catch {
            return nil
        }
    }

    @ViewBuilder
    private func tribeImage(for tribe: Tribe) -> some View {
        if let cachedImage = cachedTribeImage(for: tribe) {
            cachedImage
                .resizable()
                .scaledToFill()
        } else if let url = tribe.photoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            tribeImageCache[tribe.id] = image
                            tribeImageURLCache[tribe.id] = url
                        }
                case .empty:
                    Colors.card
                default:
                    Colors.card
                }
            }
        } else {
            Colors.card
        }
    }

    private func cachedTribeImage(for tribe: Tribe) -> Image? {
        guard let cachedImage = tribeImageCache[tribe.id],
              tribeImageURLCache[tribe.id] == tribe.photoURL else {
            return nil
        }
        return cachedImage
    }
    
    private func tripDateRange(for trip: Trip) -> String {
        let start = trip.checkIn.formatted(.dateTime.month(.abbreviated).day())
        let end = trip.returnDate.formatted(.dateTime.month(.abbreviated).day())
        return start == end ? start : "\(start)–\(end)"
    }

    private func tripImageQuery(for trip: Trip) -> String {
        let filteredScalars = trip.destination.unicodeScalars.filter { !$0.properties.isEmoji }
        let cleaned = String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? trip.destination : cleaned
    }

    private func recommendationRatingColor(_ ratingText: String) -> Color {
        let trimmed = ratingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else { return Colors.accent }
        if value >= 10 { return Colors.accent }
        if value >= 7 { return Colors.ratingGreen }
        if value >= 5 { return Colors.ratingyellow }
        return Color.red
    }

    private var selectedTripDestination: String {
        selectedTrip?.destination ?? "Costa Rica"
    }

    private var selectedTripTitle: String {
        let filteredScalars = selectedTripDestination
            .unicodeScalars
            .filter { !$0.properties.isEmoji }
        return String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    MyTripsView()
}
