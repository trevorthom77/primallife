import SwiftUI

struct TravelStatsView: View {
    @Environment(\.dismiss) private var dismiss
    let countries: [ProfileCountry]
    let onDeleteCountry: (ProfileCountry) -> Void
    @State private var selectedCountry: ProfileCountry?
    private let continents = [
        "Africa",
        "Antarctica",
        "Asia",
        "Europe",
        "North America",
        "Oceania",
        "South America"
    ]
    
    var body: some View {
        let visitedISOSet = Set(countries.map { $0.isoCode.uppercased() })
        let totalsByContinent = Dictionary(grouping: CountryDatabase.all, by: { $0.continent })
            .mapValues { $0.count }
        let visitedByContinent = Dictionary(
            grouping: CountryDatabase.all.filter { visitedISOSet.contains($0.isoCode.uppercased()) },
            by: { $0.continent }
        )
        .mapValues { $0.count }

        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BackButton {
                        dismiss()
                    }
                    
                    Text("Countries")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    VStack(spacing: 12) {
                        if countries.isEmpty {
                            Text("No countries yet.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                        } else {
                            ForEach(countries) { country in
                                TravelCard(
                                    flag: country.flag,
                                    location: country.name,
                                    dates: country.note,
                                    imageQuery: country.imageQuery,
                                    showsParticipants: false,
                                    height: 150
                                )
                                .overlay(alignment: .topTrailing) {
                                    Button(action: {
                                        selectedCountry = country
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Continents")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        ForEach(continents, id: \.self) { continent in
                            let total = totalsByContinent[continent, default: 0]
                            let visitedCount = visitedByContinent[continent, default: 0]
                            let percent = total == 0 ? 0 : Double(visitedCount) / Double(total)

                            HStack(spacing: 12) {
                                TravelCard(
                                    flag: "",
                                    location: "",
                                    dates: "",
                                    imageQuery: continent,
                                    showsParticipants: false,
                                    width: 110,
                                    height: 80,
                                    cornerRadius: 8
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(continent)
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)

                                    Text("\(visitedCount) of \(total) Countries")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                ZStack {
                                    Circle()
                                        .stroke(Colors.secondaryText.opacity(0.2), lineWidth: 5)

                                    Circle()
                                        .trim(from: 0, to: percent)
                                        .stroke(
                                            Colors.accent,
                                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))

                                    Text("\(Int(percent * 100))%")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                .frame(width: 48, height: 48)
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $selectedCountry) { country in
            TravelStatsMoreSheetView(country: country) {
                onDeleteCountry(country)
            }
        }
    }
}

private struct TravelStatsMoreSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirm = false
    let country: ProfileCountry
    let onDelete: () -> Void

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
                    Text("Delete Country")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.secondaryText)

                    Text("This removes \(country.name) from your countries list.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)

                    Button(action: {
                        isShowingDeleteConfirm = true
                    }) {
                        HStack {
                            Text("Delete Country")
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
                    title: "Delete Country",
                    message: "This removes \(country.name) from your countries list.",
                    confirmTitle: "Delete",
                    isDestructive: true,
                    confirmAction: {
                        isShowingDeleteConfirm = false
                        onDelete()
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
