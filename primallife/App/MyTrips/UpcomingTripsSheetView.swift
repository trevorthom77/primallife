import SwiftUI

struct UpcomingTripsSheetView: View {
    let trips: [Trip]
    let tripImageDetails: [UUID: UnsplashImageDetails]
    let onDeleteTrip: (Trip) -> Void
    @State private var selectedTrip: Trip?
    @State private var tribeImageCache: [UUID: Image] = [:]
    @State private var tribeImageURLCache: [UUID: URL] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if trips.isEmpty {
                            VStack(spacing: 12) {
                                Text("No upcoming trips yet")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.primaryText)

                                Text("Add your next destination to see it here.")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(trips) { trip in
                                ZStack(alignment: .topTrailing) {
                                    NavigationLink {
                                        UpcomingTripsFullView(
                                            trip: trip,
                                            prefetchedDetails: tripImageDetails[trip.id],
                                            tribeImageCache: $tribeImageCache,
                                            tribeImageURLCache: $tribeImageURLCache
                                        )
                                    } label: {
                                        UpcomingTripPlaceCard(
                                            imageURL: tripImageDetails[trip.id]?.url,
                                            location: trip.destination,
                                            flag: tripFlag(for: trip),
                                            title: tripTitle(for: trip)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        selectedTrip = trip
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .font(.travelBody)
                                            .foregroundStyle(Colors.primaryText)
                                            .frame(width: 36, height: 36)
                                            .background(Colors.card.opacity(0.9))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 12)
                                    .padding(.trailing, 12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(item: $selectedTrip) { trip in
            UpcomingTripsMoreSheetView(
                trip: trip,
                onDeleteTrip: {
                    onDeleteTrip(trip)
                }
            )
        }
    }

    private func tripFlag(for trip: Trip) -> String {
        let emojiScalars = trip.destination.unicodeScalars.filter { $0.properties.isEmoji }
        return String(String.UnicodeScalarView(emojiScalars))
            .trimmingCharacters(in: .whitespaces)
    }

    private func tripTitle(for trip: Trip) -> String {
        let filteredScalars = trip.destination.unicodeScalars.filter { !$0.properties.isEmoji }
        return String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespaces)
    }
}

private struct UpcomingTripPlaceCard: View {
    let imageURL: URL?
    let location: String
    let flag: String
    let title: String

    private let customImageNames = [
        "italy",
        "greece",
        "puerto rico",
        "costa rica",
        "australia",
        "jamaica",
        "switzerland"
    ]

    private var customImageName: String? {
        let candidate = location.trimmingCharacters(in: .whitespacesAndNewlines)

        for name in customImageNames where candidate.localizedCaseInsensitiveContains(name) {
            return name
        }

        return nil
    }

    var body: some View {
        ZStack {
            if let customImageName {
                Image(customImageName)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Colors.card
                }
            } else {
                Colors.card
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 8) {
                if !flag.isEmpty {
                    Text(flag)
                }
                Text(title)
            }
            .font(.travelTitle)
            .foregroundStyle(Colors.card)
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
        .clipped()
    }
}

private struct UpcomingTripsMoreSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirm = false
    let trip: Trip
    let onDeleteTrip: () -> Void

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Delete Trip")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.secondaryText)

                    Text("This removes \(trip.destination) from your upcoming list.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)

                    Button(action: {
                        isShowingDeleteConfirm = true
                    }) {
                        HStack {
                            Text("Delete Trip")
                                .font(.travelDetail)
                                .foregroundStyle(Color.red)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                Spacer()
            }
            .padding(20)
        }
        .overlay {
            if isShowingDeleteConfirm {
                confirmationOverlay(
                    title: "Delete Trip",
                    message: "This removes \(trip.destination) from your upcoming list.",
                    confirmTitle: "Delete",
                    isDestructive: true,
                    confirmAction: {
                        isShowingDeleteConfirm = false
                        onDeleteTrip()
                        dismiss()
                    },
                    cancelAction: {
                        isShowingDeleteConfirm = false
                    }
                )
            }
        }
        .presentationDetents([.height(320)])
        .presentationBackground(Colors.background)
        .presentationDragIndicator(.hidden)
    }

    private func confirmationOverlay(
        title: String,
        message: String,
        confirmTitle: String,
        isDestructive: Bool,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            Colors.primaryText
                .opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    cancelAction()
                }

            VStack(spacing: 16) {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                Text(message)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(action: cancelAction) {
                        Text("Cancel")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Colors.secondaryText.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: confirmAction) {
                        Text(confirmTitle)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isDestructive ? Color.red : Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
}
