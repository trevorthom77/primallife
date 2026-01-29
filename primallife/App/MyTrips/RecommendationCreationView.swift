import SwiftUI
import Supabase

struct RecommendationCreationView: View {
    let trip: Trip
    let imageDetails: UnsplashImageDetails?
    let supabase: SupabaseClient?
    @ObservedObject var viewModel: MyTripsViewModel
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDetails = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Create a Recommendation")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("Share a place you love for this trip. Add secret spots too, like shops, nature hideaways, and local gems. Recommendations help others plan their trip so travelers can discover new places.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TravelCard(
                    flag: "",
                    location: trip.destination,
                    dates: "",
                    imageQuery: trip.destination,
                    showsParticipants: false,
                    showsAttribution: false,
                    prefetchedDetails: imageDetails
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingDetails = true
                }) {
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
        .navigationDestination(isPresented: $isShowingDetails) {
            RecommendationDetailsView(
                destination: trip.destination,
                countryCode: trip.countryCode,
                placeType: trip.placeType,
                supabase: supabase,
                viewModel: viewModel,
                onFinish: {
                    isShowingDetails = false
                    onFinish()
                }
            )
        }
    }
}

private struct RecommendationDetailsView: View {
    let destination: String
    let countryCode: String?
    let placeType: String?
    let supabase: SupabaseClient?
    @ObservedObject var viewModel: MyTripsViewModel
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recommendationName = ""
    @State private var recommendationSubtext = ""
    @State private var recommendationRating = ""
    @FocusState private var isNameFocused: Bool
    @FocusState private var isNoteFocused: Bool
    @FocusState private var isRatingFocused: Bool
    @State private var isShowingReview = false
    private let nameLimit = 60

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendation name")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 8) {
                        TextField("", text: $recommendationName)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .focused($isNameFocused)
                            .onChange(of: recommendationName) { _, newValue in
                                if newValue.count > nameLimit {
                                    recommendationName = String(newValue.prefix(nameLimit))
                                }
                            }

                        HStack {
                            Text("Up to \(nameLimit) characters")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                            Spacer()
                            Text("\(recommendationName.count)/\(nameLimit)")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextEditor(text: $recommendationSubtext)
                        .font(.travelBody)
                        .foregroundStyle(Colors.primaryText)
                        .padding(12)
                        .frame(height: 140)
                        .scrollContentBackground(.hidden)
                        .focused($isNoteFocused)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating (1-10)")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextField("", text: $recommendationRating)
                        .font(.travelDetail)
                        .foregroundStyle(Colors.primaryText)
                        .padding()
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .keyboardType(.decimalPad)
                        .focused($isRatingFocused)
                        .onChange(of: recommendationRating) { _, newValue in
                            let sanitized = sanitizeRating(newValue)
                            if sanitized != newValue {
                                recommendationRating = sanitized
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isNameFocused = false
            isNoteFocused = false
            isRatingFocused = false
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingReview = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingReview) {
            RecommendationReviewView(
                destination: destination,
                countryCode: countryCode,
                placeType: placeType,
                recommendationName: recommendationName,
                recommendationSubtext: recommendationSubtext,
                recommendationRating: recommendationRating,
                supabase: supabase,
                viewModel: viewModel,
                onFinish: onFinish
            )
        }
    }

    private func sanitizeRating(_ value: String) -> String {
        var result = ""
        var hasDecimal = false
        var decimalCount = 0

        for character in value {
            if character.isWholeNumber {
                if hasDecimal {
                    if decimalCount >= 1 { continue }
                    decimalCount += 1
                }
                result.append(character)
            } else if character == "." && !hasDecimal {
                hasDecimal = true
                result.append(character)
            }
        }

        if let number = Double(result), number > 10 {
            return "10"
        }

        return result
    }

    private var trimmedName: String {
        recommendationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String {
        recommendationSubtext.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedRating: String {
        recommendationRating.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isContinueEnabled: Bool {
        guard !trimmedName.isEmpty, !trimmedNote.isEmpty else { return false }
        guard let ratingValue = Double(trimmedRating) else { return false }
        return (1...10).contains(ratingValue)
    }
}

private struct RecommendationReviewView: View {
    let destination: String
    let countryCode: String?
    let placeType: String?
    let recommendationName: String
    let recommendationSubtext: String
    let recommendationRating: String
    let supabase: SupabaseClient?
    @ObservedObject var viewModel: MyTripsViewModel
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isCreating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Review your recommendation")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("This is what travelers will see.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                }

                VStack(alignment: .leading, spacing: 16) {
                    if !trimmedName.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendation name")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            Text(trimmedName)
                                .font(.travelBody)
                                .foregroundStyle(Colors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !trimmedNote.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            Text(trimmedNote)
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !trimmedRating.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rating")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            Text(trimmedRating)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.tertiaryText)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(ratingColor(for: trimmedRating))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(16)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    guard !isCreating else { return }
                    isCreating = true
                    Task {
                        let ratingValue = Double(trimmedRating) ?? 0
                        await viewModel.addRecommendation(
                            destination: destination,
                            countryCode: countryCode,
                            placeType: placeType,
                            name: recommendationName,
                            note: recommendationSubtext,
                            rating: ratingValue,
                            supabase: supabase
                        )
                        await MainActor.run {
                            isCreating = false
                            onFinish()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Create Recommendation")
                            .font(.travelDetail)
                            .foregroundColor(Colors.tertiaryText)

                        if isCreating {
                            ProgressView()
                                .tint(Colors.tertiaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Colors.accent)
                    .cornerRadius(16)
                }
                .disabled(!isCreateEnabled)
                .opacity(isCreateEnabled ? 1 : 0.6)
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

    private func ratingColor(for ratingText: String) -> Color {
        let trimmed = ratingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else { return Colors.accent }
        if value >= 10 { return Colors.accent }
        if value >= 7 { return Colors.ratingGreen }
        if value >= 5 { return Colors.ratingyellow }
        return Color.red
    }

    private var trimmedName: String {
        recommendationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String {
        recommendationSubtext.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedRating: String {
        recommendationRating.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isCreateEnabled: Bool {
        guard !trimmedName.isEmpty, !trimmedNote.isEmpty else { return false }
        guard let ratingValue = Double(trimmedRating) else { return false }
        return (1...10).contains(ratingValue)
    }
}
