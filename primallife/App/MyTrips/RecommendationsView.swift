import SwiftUI
import Supabase

struct RecommendationsView: View {
    let trip: Trip
    @ObservedObject var viewModel: MyTripsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var selectedRecommendation: Recommendation?

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
                    VStack(alignment: .leading, spacing: 12) {
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
                                let currentUserID = supabase?.auth.currentUser?.id
                                let isCreator = currentUserID == recommendation.creatorID
                                let ratingColor = recommendationRatingColor(ratingText)

                                RecommendationCard(
                                    recommendation: recommendation,
                                    creatorName: creatorName,
                                    ratingText: ratingText,
                                    ratingColor: ratingColor,
                                    showsMoreButton: isCreator,
                                    onMoreTapped: {
                                        selectedRecommendation = recommendation
                                    }
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
        .sheet(item: $selectedRecommendation) { recommendation in
            RecommendationMoreSheetView(
                recommendation: recommendation,
                onDeleteRecommendation: {
                    Task {
                        await viewModel.deleteRecommendation(recommendation: recommendation, supabase: supabase)
                    }
                }
            )
        }
        .task {
            await viewModel.loadRecommendations(
                destination: trip.destination,
                countryCode: trip.countryCode,
                placeType: trip.placeType,
                supabase: supabase
            )
        }
    }

    private var recommendations: [Recommendation] {
        guard let lookupKey = viewModel.recommendationsKey(for: trip) else { return [] }
        return viewModel.recommendationsByDestination[lookupKey] ?? []
    }

    private var isLoading: Bool {
        guard let lookupKey = viewModel.recommendationsKey(for: trip) else { return false }
        return viewModel.loadingRecommendationDestinations.contains(lookupKey)
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
    let ratingText: String
    let ratingColor: Color
    let showsMoreButton: Bool
    let onMoreTapped: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.name)
                        .font(.travelBodySemibold)
                        .foregroundStyle(Colors.primaryText)
                        .lineLimit(2)

                    Text(recommendation.note)
                        .font(.travelDetail)
                        .foregroundStyle(Colors.secondaryText)
                        .lineLimit(isExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)

                    if shouldShowMore {
                        Button(isExpanded ? "Less" : "More") {
                            isExpanded.toggle()
                        }
                        .font(.badgeDetail)
                        .foregroundStyle(Colors.accent)
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .trailing, spacing: 8) {
                    if showsMoreButton {
                        Button(action: onMoreTapped) {
                            Image(systemName: "ellipsis")
                                .font(.tripsfont)
                                .foregroundStyle(Colors.primaryText)
                                .frame(width: 32, height: 32)
                                .background(Colors.card.opacity(0.9))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(ratingText)
                        .font(.tripsfont)
                        .foregroundStyle(Colors.tertiaryText)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(ratingColor)
                        .clipShape(Capsule())
                }
            }

            if let creatorName {
                NavigationLink {
                    OthersProfileView(userID: recommendation.creatorID)
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended by")
                                .font(.badgeDetail)
                                .foregroundStyle(Colors.tertiaryText)
                            Text(creatorName)
                                .font(.tripsfont)
                                .foregroundStyle(Colors.primaryText)
                        }

                        Spacer()

                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var shouldShowMore: Bool {
        recommendation.note.count > 120
    }
}

private struct RecommendationMoreSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirm = false
    let recommendation: Recommendation
    let onDeleteRecommendation: () -> Void

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
                    Text("Delete Recommendation")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.secondaryText)

                    Text("This removes \(recommendation.name) from your recommendations.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)

                    Button(action: {
                        isShowingDeleteConfirm = true
                    }) {
                        HStack {
                            Text("Delete Recommendation")
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
                    title: "Delete Recommendation",
                    message: "This removes \(recommendation.name) from your recommendations.",
                    confirmTitle: "Delete",
                    isDestructive: true,
                    confirmAction: {
                        isShowingDeleteConfirm = false
                        onDeleteRecommendation()
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
