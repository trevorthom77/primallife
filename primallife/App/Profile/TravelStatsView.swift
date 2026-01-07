import SwiftUI

struct TravelStatsView: View {
    @Environment(\.dismiss) private var dismiss
    let countries: [ProfileCountry]
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
                                Button(action: {}) {
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

                    Text("Continents")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 12) {
                        ForEach(continents, id: \.self) { continent in
                            let total = totalsByContinent[continent, default: 0]
                            let visitedCount = visitedByContinent[continent, default: 0]
                            let percent = total == 0
                                ? 0
                                : Int((Double(visitedCount) / Double(total)) * 100)

                            VStack(alignment: .leading, spacing: 8) {
                                TravelCard(
                                    flag: "",
                                    location: continent,
                                    dates: "",
                                    imageQuery: continent,
                                    showsParticipants: false,
                                    height: 150
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    Text("\(visitedCount) \(visitedCount == 1 ? "Country" : "Countries")")
                                    Spacer()
                                    Text("\(percent)%")
                                }
                                .font(.tripsfont)
                                .foregroundStyle(Colors.secondaryText)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
    }
}
