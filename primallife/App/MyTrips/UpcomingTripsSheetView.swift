import SwiftUI

struct UpcomingTripsSheetView: View {
    let trips: [Trip]
    let tripImageDetails: [UUID: UnsplashImageDetails]
    @State private var isShowingMoreSheet = false

    var body: some View {
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
                            UpcomingTripPlaceCard(
                                imageURL: tripImageDetails[trip.id]?.url,
                                location: trip.destination,
                                flag: tripFlag(for: trip),
                                title: tripTitle(for: trip),
                                onMoreTapped: {
                                    isShowingMoreSheet = true
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $isShowingMoreSheet) {
            UpcomingTripsMoreSheetView()
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
    let onMoreTapped: () -> Void

    private let customImageNames = [
        "miami",
        "aruba",
        "florida",
        "italy",
        "hawaii",
        "greece",
        "charleston",
        "california",
        "bahamas",
        "puerto rico",
        "costa rica",
        "australia",
        "queensland"
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
        .overlay(alignment: .topTrailing) {
            Button(action: onMoreTapped) {
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
        .clipped()
    }
}

private struct UpcomingTripsMoreSheetView: View {
    @Environment(\.dismiss) private var dismiss

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

                Spacer()
            }
            .padding(20)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
    }
}
