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
                                let photoURL = recommendationPhotoURL(for: recommendation)
                                let ratingColor = recommendationRatingColor(ratingText)

                                RecommendationCard(
                                    recommendation: recommendation,
                                    creatorName: creatorName,
                                    creatorAvatarURL: creatorAvatarURL,
                                    ratingText: ratingText,
                                    ratingColor: ratingColor,
                                    photoURL: photoURL
                                )
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

struct RecommendationCard: View {
    let recommendation: Recommendation
    let creatorName: String?
    let creatorAvatarURL: URL?
    let ratingText: String
    let ratingColor: Color
    let photoURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let photoURL {
                    AsyncImage(url: photoURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Colors.secondaryText.opacity(0.1)
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(Colors.primaryText.opacity(0.02))
                }

                Text(ratingText)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.tertiaryText)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(ratingColor)
                    .clipShape(Capsule())
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(recommendation.name)
                    .font(.travelTitle)
                    .foregroundStyle(Colors.primaryText)
                    .lineLimit(2)

                Text(recommendation.note)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if creatorName != nil || creatorAvatarURL != nil {
                    NavigationLink {
                        OthersProfileView(userID: recommendation.creatorID)
                    } label: {
                        HStack(spacing: 10) {
                            if let creatorAvatarURL {
                                AsyncImage(url: creatorAvatarURL) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Colors.secondaryText.opacity(0.3)
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                            }

                            if let creatorName {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Recommended by")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.tertiaryText)
                                    Text(creatorName)
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                            }

                            Spacer()

                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
