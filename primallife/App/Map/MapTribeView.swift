import SwiftUI

struct MapTribeView: View {
    @Environment(\.dismiss) private var dismiss

    private let exampleTrips: [String] = [
        "Surf Trip in Costa Rica",
        "Island Hopping in Fiji",
        "Snorkel Week in Belize",
        "Sailing the Bahamas",
        "Rainforest Escape in Puerto Rico",
        "Beach Hike in Maui"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                Text("Create a Map Tribe")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(exampleTrips, id: \.self) { example in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Colors.contentview)
                                .frame(width: 48, height: 48)

                            Text(example)
                                .font(.tripsfont)
                                .foregroundStyle(Colors.primaryText)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {}) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
    }
}
