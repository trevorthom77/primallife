import SwiftUI
import Supabase

struct RecommendationsView: View {
    let destination: String
    @ObservedObject var viewModel: MyTripsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase

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

                Text("Recommendations")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading && recommendations.isEmpty {
                            ProgressView()
                                .tint(Colors.accent)
                                .padding(.vertical, 4)
                        } else if recommendations.isEmpty {
                            Text("No recommendations yet")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(recommendations) { recommendation in
                                let ratingText = String(format: "%.1f", recommendation.rating)
                                let creatorName = viewModel.creatorName(for: recommendation.creatorID)
                                let creatorAvatarURL = viewModel.creatorAvatarURL(
                                    for: recommendation.creatorID,
                                    supabase: supabase
                                )

                                VStack(alignment: .leading, spacing: 12) {
                                    if let photoURL = recommendationPhotoURL(for: recommendation) {
                                        AsyncImage(url: photoURL) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                Colors.secondaryText.opacity(0.2)
                                            }
                                        }
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }

                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(recommendation.name)
                                                .font(.travelTitle)
                                                .foregroundStyle(Colors.primaryText)

                                            Text(recommendation.destination)
                                                .font(.travelDetail)
                                                .foregroundStyle(Colors.secondaryText)
                                        }

                                        Spacer()

                                        Text(ratingText)
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.tertiaryText)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(recommendationRatingColor(ratingText))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    Text(recommendation.note)
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if creatorName != nil || creatorAvatarURL != nil {
                                        HStack {
                                            Spacer()

                                            NavigationLink {
                                                OthersProfileView(userID: recommendation.creatorID)
                                            } label: {
                                                HStack(spacing: 8) {
                                                    if let creatorName {
                                                        Text(creatorName)
                                                            .font(.travelDetail)
                                                            .foregroundStyle(Colors.secondaryText)
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                    }

                                                    if let creatorAvatarURL {
                                                        AsyncImage(url: creatorAvatarURL) { phase in
                                                            if let image = phase.image {
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                            } else {
                                                                Colors.secondaryText.opacity(0.2)
                                                            }
                                                        }
                                                        .frame(width: 28, height: 28)
                                                        .clipShape(Circle())
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Colors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .navigationBarBackButtonHidden(true)
        .task {
            let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedDestination.isEmpty else { return }
            await viewModel.loadRecommendations(for: trimmedDestination, supabase: supabase)
        }
    }

    private var recommendations: [Recommendation] {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return viewModel.recommendationsByDestination[trimmed] ?? []
    }

    private var isLoading: Bool {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return viewModel.loadingRecommendationDestinations.contains(trimmed)
    }

    private func recommendationPhotoURL(for recommendation: Recommendation) -> URL? {
        guard let photoPath = recommendation.photoURL else { return nil }
        if let url = URL(string: photoPath), url.scheme != nil {
            return url
        }
        guard let supabase else { return nil }
        do {
            return try supabase.storage
                .from("recommendation-photos")
                .getPublicURL(path: photoPath)
        } catch {
            return nil
        }
    }

    private func recommendationRatingColor(_ ratingText: String) -> Color {
        let trimmed = ratingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else { return Colors.accent }
        if value >= 10 { return Colors.accent }
        if value >= 7 { return Colors.ratingGreen }
        if value >= 5 { return Colors.ratingyellow }
        return Color.red
    }
}
