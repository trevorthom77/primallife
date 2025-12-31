import SwiftUI

struct UpcomingTripsFullView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip
    let prefetchedDetails: UnsplashImageDetails?
    @State private var selectedTab: UpcomingTripsTab = .travelers

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
                                Text(tab.rawValue)
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
