import SwiftUI
import Supabase

struct UpcomingTripsFullView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    let trip: Trip
    let prefetchedDetails: UnsplashImageDetails?
    @Binding var tribeImageCache: [UUID: Image]
    @Binding var tribeImageURLCache: [UUID: URL]
    @State private var travelerImageCache: [UUID: Image] = [:]
    @State private var travelerImageURLCache: [UUID: URL] = [:]
    @State private var tribeMemberImageCache: [UUID: Image] = [:]
    @State private var tribeMemberImageURLCache: [UUID: URL] = [:]
    @State private var selectedTab: UpcomingTripsTab = .travelers
    @State private var filterCheckInDate: Date?
    @State private var filterReturnDate: Date?
    @State private var filterMinAge: Int?
    @State private var filterMaxAge: Int?
    @State private var filterGender: String?
    @State private var filterOriginID: String?
    @State private var filterTribeType: String?
    @State private var filterTravelDescription: String?
    @State private var filterInterests: Set<String> = []
    @StateObject private var viewModel = MyTripsViewModel()

    private enum UpcomingTripsTab: String, CaseIterable {
        case travelers = "Travelers"
        case tribes = "Tribes"
    }

    init(
        trip: Trip,
        prefetchedDetails: UnsplashImageDetails?,
        tribeImageCache: Binding<[UUID: Image]>,
        tribeImageURLCache: Binding<[UUID: URL]>,
        startOnTribesTab: Bool = false
    ) {
        self.trip = trip
        self.prefetchedDetails = prefetchedDetails
        _tribeImageCache = tribeImageCache
        _tribeImageURLCache = tribeImageURLCache
        _selectedTab = State(initialValue: startOnTribesTab ? .tribes : .travelers)
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()

                    NavigationLink {
                        UpcomingTripsFilterView(
                            filterCheckInDate: $filterCheckInDate,
                            filterReturnDate: $filterReturnDate,
                            filterMinAge: $filterMinAge,
                            filterMaxAge: $filterMaxAge,
                            filterGender: $filterGender,
                            filterOriginID: $filterOriginID,
                            filterTribeType: $filterTribeType,
                            filterTravelDescription: $filterTravelDescription,
                            filterInterests: $filterInterests,
                            showsTribeFilters: selectedTab == .tribes
                        )
                    } label: {
                        Text("Filter")
                            .font(.travelBodySemibold)
                            .foregroundStyle(Colors.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Colors.card)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    TravelCard(
                        flag: "",
                        location: trip.destination,
                        dates: tripDateRange(for: trip),
                        imageQuery: tripImageQuery(for: trip),
                        participantCount: travelerCount,
                        prefetchedDetails: prefetchedDetails
                    )

                    Spacer()
                }

                HStack {
                    HStack(spacing: 8) {
                        ForEach(UpcomingTripsTab.allCases, id: \.self) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                HStack(spacing: 6) {
                                    Text(tab.rawValue)
                                    if tab == .tribes {
                                        Text(tribeCountText)
                                    } else if tab == .travelers {
                                        Text(travelerCountText)
                                    }
                                }
                                .font(.travelDetail)
                                .foregroundStyle(selectedTab == tab ? Colors.tertiaryText : Colors.primaryText)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    selectedTab == tab
                                    ? Colors.accent
                                    : Colors.secondaryText.opacity(0.18)
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }

                if selectedTab == .tribes {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let tribes = filteredTribesForTrip {
                                if tribes.isEmpty {
                                    Text("No tribes yet.")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.secondaryText)
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(tribes) { tribe in
                                        NavigationLink {
                                            TribesSocialView(
                                                imageURL: tribe.photoURL,
                                                title: tribe.name,
                                                location: trip.destination,
                                                flag: "",
                                                endDate: tribe.endDate,
                                                minAge: tribe.minAge,
                                                maxAge: tribe.maxAge,
                                                createdAt: tribe.createdAt,
                                                gender: tribe.gender,
                                                aboutText: tribe.description,
                                                interests: tribe.interests,
                                                placeName: trip.destination,
                                                tribeID: tribe.id,
                                                createdBy: viewModel.creatorName(for: tribe.ownerID),
                                                createdByAvatarPath: viewModel.creatorAvatarPath(for: tribe.ownerID),
                                                isCreator: supabase?.auth.currentUser?.id == tribe.ownerID,
                                                onDelete: {
                                                    Task {
                                                        await loadTribesForTrip(force: true)
                                                    }
                                                },
                                                initialHeaderImage: cachedTribeImage(for: tribe)
                                            )
                                        } label: {
                                            VStack(alignment: .leading, spacing: 0) {
                                                tribeImage(for: tribe)
                                                    .frame(height: 160)
                                                    .frame(maxWidth: .infinity)
                                                    .clipped()
                                                    .overlay(alignment: .bottomLeading) {
                                                        HStack(spacing: 6) {
                                                            Image(systemName: "calendar")
                                                            Text(tribeDateRangeText(tribe))
                                                        }
                                                        .font(.badgeDetail)
                                                        .foregroundStyle(Colors.primaryText)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(Colors.card.opacity(0.9))
                                                        .clipShape(Capsule())
                                                        .padding(12)
                                                    }

                                                HStack(alignment: .center, spacing: 12) {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text(trip.destination)
                                                            .font(.tripsfont)
                                                            .foregroundStyle(Colors.secondaryText)

                                                        Text(tribe.name)
                                                            .font(.travelTitle)
                                                            .foregroundStyle(Colors.primaryText)
                                                    }

                                                    Spacer()

                                                    HStack(spacing: -8) {
                                                        ForEach(
                                                            viewModel.tribeMemberIDs(for: tribe.id).prefix(3),
                                                            id: \.self
                                                        ) { memberID in
                                                            tribeMemberAvatar(for: memberID)
                                                        }

                                                        ZStack {
                                                            Circle()
                                                                .fill(Colors.background)
                                                                .frame(width: 36, height: 36)
                                                                .overlay {
                                                                    Circle()
                                                                        .stroke(Colors.card, lineWidth: 3)
                                                                }

                                                            Text("\(viewModel.memberCount(for: tribe.id))+")
                                                                .font(.badgeDetail)
                                                                .foregroundStyle(Colors.primaryText)
                                                        }
                                                    }
                                                }
                                                .padding(16)
                                                .background(Colors.card)
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .contentShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else if isLoadingTribesForTrip {
                                ProgressView()
                                    .tint(Colors.accent)
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if let travelers = filteredTravelersForTrip {
                                if travelers.isEmpty {
                                    Text("No travelers yet.")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.secondaryText)
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(travelers, id: \.self) { travelerID in
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

                                                            if let dateRangeText = travelerDateRangeText(for: travelerID) {
                                                                Text(dateRangeText)
                                                                    .font(.travelDetail)
                                                                    .foregroundStyle(Colors.secondaryText)
                                                                    .lineLimit(1)
                                                            }
                                                        }

                                                        let tripLocation = viewModel.travelerTripLocation(
                                                            for: travelerID,
                                                            tripID: trip.id
                                                        )
                                                        if tripLocation.flag != nil || tripLocation.name != nil {
                                                            HStack(spacing: 8) {
                                                                if let flag = tripLocation.flag {
                                                                    Text(flag)
                                                                        .font(.travelDetail)
                                                                        .foregroundStyle(Colors.primaryText)
                                                                }

                                                                if let locationName = tripLocation.name {
                                                                    Text(locationName)
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
                            } else if isLoadingTravelersForTrip {
                                ProgressView()
                                    .tint(Colors.accent)
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .task(id: selectedTab) {
            if selectedTab == .tribes {
                await loadTribesForTrip()
            } else {
                await loadTravelersForTrip()
            }
        }
        .task(id: trip.id) {
            await loadTribesForTrip()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func tripDateRange(for trip: Trip) -> String {
        let start = trip.checkIn.formatted(.dateTime.month(.abbreviated).day())
        let end = trip.returnDate.formatted(.dateTime.month(.abbreviated).day())
        return start == end ? start : "\(start)–\(end)"
    }

    private func travelerDateRangeText(for travelerID: UUID) -> String? {
        guard let dateRange = viewModel.travelerDatesByTrip[trip.id]?[travelerID] else { return nil }
        let start = dateRange.checkIn.formatted(.dateTime.month(.abbreviated).day())
        let end = dateRange.returnDate.formatted(.dateTime.month(.abbreviated).day())
        return start == end ? start : "\(start)–\(end)"
    }

    private func tribeDateRangeText(_ tribe: Tribe) -> String {
        let start = tribe.createdAt.formatted(.dateTime.month(.abbreviated).day())
        let end = tribe.endDate.formatted(.dateTime.month(.abbreviated).day().year())
        return "\(start) - \(end)"
    }

    private func tripImageQuery(for trip: Trip) -> String {
        let filteredScalars = trip.destination.unicodeScalars.filter { !$0.properties.isEmoji }
        let cleaned = String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? trip.destination : cleaned
    }

    @MainActor
    private func loadTribesForTrip(force: Bool = false) async {
        if viewModel.isLoadingTribes(tripID: trip.id) { return }
        if !force, viewModel.tribesByTrip[trip.id] != nil { return }
        await viewModel.loadTribes(for: trip, supabase: supabase)
    }

    @MainActor
    private func loadTravelersForTrip(force: Bool = false) async {
        if viewModel.isLoadingTravelers(tripID: trip.id) { return }
        if !force, viewModel.travelersByTrip[trip.id] != nil { return }
        await viewModel.loadTravelers(for: trip, supabase: supabase)
    }

    private var tribesForTrip: [Tribe]? {
        viewModel.tribesByTrip[trip.id]
    }

    private var filteredTribesForTrip: [Tribe]? {
        guard let tribes = tribesForTrip else { return nil }
        let normalizedFilter = filterTribeType?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        let usesTypeFilter = !normalizedFilter.isEmpty && normalizedFilter != "everyone"

        let minAgeFilter = filterMinAge
        let maxAgeFilter = filterMaxAge
        let isAgeFilterActive = minAgeFilter != nil || maxAgeFilter != nil

        let interestsFilter = filterInterests
        let usesInterestsFilter = !interestsFilter.isEmpty

        guard usesTypeFilter || isAgeFilterActive || usesInterestsFilter else { return tribes }

        return tribes.filter { tribe in
            let matchesType: Bool = {
                guard usesTypeFilter else { return true }
                let tribeGender = tribe.gender
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if normalizedFilter.contains("girl") {
                    return tribeGender.contains("girl")
                }
                if normalizedFilter.contains("boy") {
                    return tribeGender.contains("boy")
                }
                return true
            }()

            let matchesAge: Bool = {
                guard isAgeFilterActive else { return true }
                guard let minAge = tribe.minAge, let maxAge = tribe.maxAge else { return true }
                if let minAgeFilter, maxAge < minAgeFilter { return false }
                if let maxAgeFilter, minAge > maxAgeFilter { return false }
                return true
            }()

            let matchesInterests: Bool = {
                guard usesInterestsFilter else { return true }
                return tribe.interests.contains { interestsFilter.contains($0) }
            }()

            return matchesType && matchesAge && matchesInterests
        }
    }

    private var travelersForTrip: [UUID]? {
        viewModel.travelersByTrip[trip.id]
    }

    private var filteredTravelersForTrip: [UUID]? {
        guard let travelers = travelersForTrip else { return nil }
        let currentUserID = supabase?.auth.currentUser?.id
        let visibleTravelers = travelers.filter { $0 != currentUserID }

        let dateFilterRange: (start: Date, end: Date)? = {
            guard let filterCheckInDate, let filterReturnDate else { return nil }
            let filterStart = Calendar.current.startOfDay(for: filterCheckInDate)
            let filterEnd = Calendar.current.startOfDay(for: filterReturnDate)
            guard filterEnd >= filterStart else { return nil }
            return (filterStart, filterEnd)
        }()

        let minAgeFilter = filterMinAge
        let maxAgeFilter = filterMaxAge
        let isAgeFilterActive = minAgeFilter != nil || maxAgeFilter != nil

        let genderFilter: String? = {
            guard let filterGender else { return nil }
            let trimmed = filterGender.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()

        let originFilter: String? = {
            guard let filterOriginID else { return nil }
            let trimmed = filterOriginID.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()

        let travelDescriptionFilter: String? = {
            guard let filterTravelDescription else { return nil }
            let trimmed = filterTravelDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()

        let interestsFilter = filterInterests

        guard dateFilterRange != nil
                || isAgeFilterActive
                || genderFilter != nil
                || originFilter != nil
                || travelDescriptionFilter != nil
                || !interestsFilter.isEmpty
        else {
            return visibleTravelers
        }

        return visibleTravelers.filter { travelerID in
            let matchesDate: Bool = {
                guard let dateFilterRange else { return true }
                guard let dateRange = viewModel.travelerDatesByTrip[trip.id]?[travelerID] else {
                    return true
                }
                let travelerStart = Calendar.current.startOfDay(for: dateRange.checkIn)
                let travelerEnd = Calendar.current.startOfDay(for: dateRange.returnDate)
                return travelerStart <= dateFilterRange.end && travelerEnd >= dateFilterRange.start
            }()

            let matchesAge: Bool = {
                guard isAgeFilterActive else { return true }
                guard let age = viewModel.creatorAge(for: travelerID) else {
                    return true
                }
                if let minAgeFilter, age < minAgeFilter { return false }
                if let maxAgeFilter, age > maxAgeFilter { return false }
                return true
            }()

            let matchesGender: Bool = {
                guard let genderFilter else { return true }
                guard let gender = viewModel.creatorGender(for: travelerID)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                    !gender.isEmpty else {
                    return false
                }
                return gender.localizedCaseInsensitiveCompare(genderFilter) == .orderedSame
            }()

            let matchesOrigin: Bool = {
                guard let originFilter else { return true }
                guard let origin = viewModel.creatorOriginID(for: travelerID) else { return false }
                return origin == originFilter
            }()

            let matchesTravelDescription: Bool = {
                guard let travelDescriptionFilter else { return true }
                guard let travelDescription = viewModel.creatorTravelDescription(for: travelerID)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                    !travelDescription.isEmpty else {
                    return false
                }
                return travelDescription.localizedCaseInsensitiveCompare(travelDescriptionFilter) == .orderedSame
            }()

            let matchesInterests: Bool = {
                guard !interestsFilter.isEmpty else { return true }
                let travelerInterests = viewModel.creatorInterests(for: travelerID)
                return travelerInterests.contains { interestsFilter.contains($0) }
            }()

            return matchesDate
                && matchesAge
                && matchesGender
                && matchesOrigin
                && matchesTravelDescription
                && matchesInterests
        }
    }

    private var tribeCountText: String {
        let count = tribesForTrip?.count ?? 0
        return "\(count)+"
    }

    private var travelerCount: Int {
        let travelers = travelersForTrip ?? []
        if let currentUserID = supabase?.auth.currentUser?.id {
            return travelers.filter { $0 != currentUserID }.count
        }
        return travelers.count
    }

    private var travelerCountText: String {
        "\(travelerCount)+"
    }

    private var isLoadingTribesForTrip: Bool {
        viewModel.isLoadingTribes(tripID: trip.id)
    }

    private var isLoadingTravelersForTrip: Bool {
        viewModel.isLoadingTravelers(tripID: trip.id)
    }

    @ViewBuilder
    private func travelerAvatar(for travelerID: UUID) -> some View {
        let avatarURL = viewModel.creatorAvatarURL(for: travelerID, supabase: supabase)

        Group {
            if let cachedImage = cachedTravelerImage(for: travelerID, avatarURL: avatarURL) {
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
                                travelerImageCache[travelerID] = image
                                travelerImageURLCache[travelerID] = avatarURL
                            }
                    case .empty:
                        Colors.secondaryText.opacity(0.3)
                    default:
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

    private func cachedTravelerImage(for travelerID: UUID, avatarURL: URL?) -> Image? {
        guard let avatarURL,
              let cachedImage = travelerImageCache[travelerID],
              travelerImageURLCache[travelerID] == avatarURL else {
            return nil
        }
        return cachedImage
    }

    @ViewBuilder
    private func tribeMemberAvatar(for memberID: UUID) -> some View {
        let avatarURL = viewModel.creatorAvatarURL(for: memberID, supabase: supabase)

        Group {
            if let cachedImage = cachedTribeMemberImage(for: memberID, avatarURL: avatarURL) {
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
                                tribeMemberImageCache[memberID] = image
                                tribeMemberImageURLCache[memberID] = avatarURL
                            }
                    default:
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Colors.card, lineWidth: 3)
        }
    }

    private func cachedTribeMemberImage(for memberID: UUID, avatarURL: URL?) -> Image? {
        guard let avatarURL,
              let cachedImage = tribeMemberImageCache[memberID],
              tribeMemberImageURLCache[memberID] == avatarURL else {
            return nil
        }
        return cachedImage
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
}
