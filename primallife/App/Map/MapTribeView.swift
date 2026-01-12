import SwiftUI

struct MapTribeView: View {
    @Environment(\.dismiss) private var dismiss

    private let exampleTrips: [(title: String, count: Int)] = [
        ("Surf Trip in Costa Rica", 101),
        ("Island Hopping in Fiji", 124),
        ("Snorkel Week in Belize", 86),
        ("Sailing the Bahamas", 139),
        ("Rainforest Escape in Puerto Rico", 117),
        ("Beach Hike in Maui", 92)
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
                    ForEach(exampleTrips, id: \.title) { example in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Colors.contentview)
                                    .frame(width: 48, height: 48)

                                Text(example.title)
                                    .font(.tripsfont)
                                    .foregroundStyle(Colors.primaryText)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            HStack(spacing: -8) {
                                Image("profile4")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile5")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile6")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile9")
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

                                    Text("\(example.count)+")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                            }
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
