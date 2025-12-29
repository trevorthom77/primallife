import SwiftUI

struct UpcomingTripsSheetView: View {
    let trips: [Trip]
    let tripImageDetails: [UUID: UnsplashImageDetails]

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
                                title: tripTitle(for: trip)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
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
        .clipped()
    }
}
