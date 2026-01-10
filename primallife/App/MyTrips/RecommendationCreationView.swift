import SwiftUI
import UIKit
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
    let supabase: SupabaseClient?
    @ObservedObject var viewModel: MyTripsViewModel
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recommendationName = ""
    @State private var recommendationSubtext = ""
    @State private var recommendationRating = ""
    @State private var recommendationPhoto: UIImage?
    @State private var recommendationPhotoData: Data?
    @FocusState private var isNameFocused: Bool
    @FocusState private var isNoteFocused: Bool
    @FocusState private var isRatingFocused: Bool
    @State private var isShowingPhotoPrompt = false
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
                        TextField("Snorkeling in Mangel Halto", text: $recommendationName)
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

                    ZStack(alignment: .topLeading) {
                        if recommendationSubtext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("We saw a lot of turtles, plus calm water and great visibility for snorkeling.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $recommendationSubtext)
                            .font(.travelBody)
                            .foregroundStyle(Colors.primaryText)
                            .padding(12)
                            .frame(height: 140)
                            .scrollContentBackground(.hidden)
                            .focused($isNoteFocused)
                    }
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating (1-10)")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextField("e.g., 5.6", text: $recommendationRating)
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
                    isShowingPhotoPrompt = true
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
        .navigationDestination(isPresented: $isShowingPhotoPrompt) {
            RecommendationPhotoPromptView(
                destination: destination,
                recommendationName: recommendationName,
                recommendationSubtext: recommendationSubtext,
                recommendationRating: recommendationRating,
                supabase: supabase,
                viewModel: viewModel,
                onFinish: onFinish,
                recommendationPhoto: $recommendationPhoto,
                recommendationPhotoData: $recommendationPhotoData
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

private struct RecommendationPhotoPromptView: View {
    let destination: String
    let recommendationName: String
    let recommendationSubtext: String
    let recommendationRating: String
    let supabase: SupabaseClient?
    @ObservedObject var viewModel: MyTripsViewModel
    let onFinish: () -> Void
    @Binding var recommendationPhoto: UIImage?
    @Binding var recommendationPhotoData: Data?
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPhotoPicker = false
    @State private var isShowingReview = false
    private let unsplashURL = URL(string: "https://unsplash.com")!

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
                    Text("Add photos?")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("Optional. Add photos of this recommendation if you want.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isShowingPhotoPicker = true
                } label: {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Colors.card)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            if let image = recommendationPhoto {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            } else {
                                VStack(spacing: 8) {
                                    Text("Add photo")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)

                                    Text("Tap to upload a photo for this recommendation.")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isShowingPhotoPicker) {
                    CroppingImagePicker(image: $recommendationPhoto, imageData: $recommendationPhotoData)
                        .ignoresSafeArea()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add beautiful, high-quality nature photos from Unsplash.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)

                    Link(destination: unsplashURL) {
                        HStack {
                            Spacer()
                            Image("unsplashblack")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 28)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
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
        .navigationDestination(isPresented: $isShowingReview) {
            RecommendationReviewView(
                destination: destination,
                recommendationName: recommendationName,
                recommendationSubtext: recommendationSubtext,
                recommendationRating: recommendationRating,
                recommendationPhoto: recommendationPhoto,
                recommendationPhotoData: recommendationPhotoData,
                supabase: supabase,
                viewModel: viewModel,
                onFinish: onFinish
            )
        }
    }
}

private struct RecommendationReviewView: View {
    let destination: String
    let recommendationName: String
    let recommendationSubtext: String
    let recommendationRating: String
    let recommendationPhoto: UIImage?
    let recommendationPhotoData: Data?
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
                    if let image = recommendationPhoto {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Colors.card)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

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
                            name: recommendationName,
                            note: recommendationSubtext,
                            rating: ratingValue,
                            photoData: recommendationPhotoData,
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

private struct CroppingImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CroppingImagePicker

        init(parent: CroppingImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let selectedImage else {
                parent.dismiss()
                return
            }

            parent.image = selectedImage
            parent.imageData = selectedImage.jpegData(compressionQuality: 0.9)
            parent.dismiss()
        }
    }
}
