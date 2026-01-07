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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Text("Continents")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 12) {
                        ForEach(continents, id: \.self) { continent in
                            TravelCard(
                                flag: "",
                                location: continent,
                                dates: "",
                                imageQuery: continent,
                                showsParticipants: false,
                                height: 150
                            )
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
