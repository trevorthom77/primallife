import SwiftUI
import Supabase

struct UpcomingTripsFullView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    let trip: Trip
    let prefetchedDetails: UnsplashImageDetails?
    @State private var selectedTab: UpcomingTripsTab = .travelers
    @StateObject private var viewModel = MyTripsViewModel()
    @State private var tribeImageCache: [UUID: Image] = [:]
    @State private var tribeImageURLCache: [UUID: URL] = [:]

    private enum UpcomingTripsTab: String, CaseIterable {
        case travelers = "Travelers"
        case tribes = "Tribes"
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
                }

                HStack {
                    TravelCard(
                        flag: "",
                        location: trip.destination,
                        dates: tripDateRange(for: trip),
                        imageQuery: tripImageQuery(for: trip),
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
                                    }
                                }
                                .font(.travelDetail)
                                .foregroundStyle(selectedTab == tab ? Colors.tertiaryText : Colors.primaryText)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity)
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
                    .frame(maxWidth: 280)

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
                                            HStack(spacing: 12) {
                                                tribeImage(for: tribe)
                                                    .frame(width: 96, height: 96)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(tribe.name)
                                                        .font(.travelDetail)
                                                        .foregroundStyle(Colors.primaryText)

                                                    Text(trip.destination)
                                                        .font(.tripsfont)
                                                        .foregroundStyle(Colors.secondaryText)
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

                                                        Text("67+")
                                                            .font(.badgeDetail)
                                                            .foregroundStyle(Colors.primaryText)
                                                    }
                                                }
                                            }
                                            .padding(18)
                                            .background(Colors.card)
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
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .task(id: selectedTab) {
            if selectedTab == .tribes {
                await loadTribesForTrip()
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

    private var tribesForTrip: [Tribe]? {
        viewModel.tribesByTrip[trip.id]
    }

    private var tribeCountText: String {
        let count = tribesForTrip?.count ?? 0
        return "\(count)+"
    }

    private var isLoadingTribesForTrip: Bool {
        viewModel.isLoadingTribes(tripID: trip.id)
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
