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
    @State private var selectedTab: UpcomingTripsTab = .travelers
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
                        UpcomingTripsFilterView()
                    } label: {
                        Text("Filter")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            if let tribes = tribesForTrip {
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
                                                        Image("profile1")
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 36, height: 36)
                                                            .clipShape(Circle())
                                                            .overlay {
                                                                Circle()
                                                                    .stroke(Colors.card, lineWidth: 3)
                                                            }

                                                        Image("profile2")
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 36, height: 36)
                                                            .clipShape(Circle())
                                                            .overlay {
                                                                Circle()
                                                                    .stroke(Colors.card, lineWidth: 3)
                                                            }

                                                        Image("profile3")
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 36, height: 36)
                                                            .clipShape(Circle())
                                                            .overlay {
                                                                Circle()
                                                                    .stroke(Colors.card, lineWidth: 3)
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
                            if let travelers = travelersForTrip {
                                let currentUserID = supabase?.auth.currentUser?.id
                                let visibleTravelers = travelers.filter { $0 != currentUserID }
                                if visibleTravelers.isEmpty {
                                    Text("No travelers yet.")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.secondaryText)
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(visibleTravelers, id: \.self) { travelerID in
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

    private var travelersForTrip: [UUID]? {
        viewModel.travelersByTrip[trip.id]
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
