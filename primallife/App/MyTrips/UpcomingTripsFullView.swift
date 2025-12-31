import SwiftUI

struct UpcomingTripsFullView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip
    let prefetchedDetails: UnsplashImageDetails?

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

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
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
}
