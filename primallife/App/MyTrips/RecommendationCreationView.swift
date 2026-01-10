import SwiftUI
import UIKit

struct RecommendationCreationView: View {
    let trip: Trip
    let imageDetails: UnsplashImageDetails?
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

                    Text("Share a place you love for this trip. Recommendations help others plan their trip so travelers can discover new places.")
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
            RecommendationDetailsView()
        }
    }
}

private struct RecommendationDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recommendationName = ""
    @State private var recommendationSubtext = ""
    @FocusState private var isNameFocused: Bool
    @FocusState private var isNoteFocused: Bool
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
                        TextField("Add a name", text: $recommendationName)
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
                            Text("Add Note")
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
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isNameFocused = false
            isNoteFocused = false
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
            RecommendationPhotoPromptView()
        }
    }
}

private struct RecommendationPhotoPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recommendationPhoto: UIImage?
    @State private var recommendationPhotoData: Data?
    @State private var isShowingPhotoPicker = false
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
