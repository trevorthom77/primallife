import SwiftUI
import PhotosUI
import Supabase

struct EditTribeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    let tribeID: UUID?
    private let originalName: String
    private let currentImageURL: URL?
    private let onUpdate: ((String, URL?) -> Void)?
    @State private var tribeName: String
    @State private var isUpdating = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newPhoto: UIImage?
    @State private var newPhotoData: Data?

    init(tribeID: UUID?, currentName: String, currentImageURL: URL?, onUpdate: ((String, URL?) -> Void)? = nil) {
        self.tribeID = tribeID
        originalName = currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.currentImageURL = currentImageURL
        self.onUpdate = onUpdate
        _tribeName = State(initialValue: currentName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()

                    Button("Update") {
                        guard isUpdateEnabled else { return }
                        Task {
                            await updateTribeName()
                        }
                    }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                        .disabled(!isUpdateEnabled || isUpdating)
                        .opacity(isUpdateEnabled && !isUpdating ? 1 : 0.6)
                }

                Text("Edit Tribe")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tribe image")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Colors.card)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if let newPhoto {
                                    Image(uiImage: newPhoto)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                } else if let currentImageURL {
                                    AsyncImage(url: currentImageURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Colors.card
                                        }
                                    }
                                } else {
                                    Text("Tap to choose a photo")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tribe name")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextField("Enter tribe name", text: $tribeName)
                        .font(.travelDetail)
                        .foregroundStyle(Colors.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .submitLabel(.done)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedPhotoItem) { _, newValue in
            loadSelectedPhoto(from: newValue)
        }
    }

    private var trimmedName: String {
        tribeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasNameChange: Bool {
        !trimmedName.isEmpty && trimmedName != originalName
    }

    private var hasNewPhoto: Bool {
        newPhotoData != nil
    }

    private var isUpdateEnabled: Bool {
        !trimmedName.isEmpty && (hasNameChange || hasNewPhoto)
    }

    private func loadSelectedPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }

            await MainActor.run {
                newPhoto = image
                newPhotoData = data
            }
        }
    }

    private func uploadTribePhotoIfNeeded(supabase: SupabaseClient, userID: UUID) async throws -> URL? {
        guard let imageData = newPhotoData else { return nil }

        let path = "\(userID)/tribes/\(UUID().uuidString).jpg"

        try await supabase.storage
            .from("tribe-photos")
            .upload(
                path,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        return try supabase.storage
            .from("tribe-photos")
            .getPublicURL(path: path)
    }

    @MainActor
    private func updateTribeName() async {
        guard let supabase,
              let tribeID,
              let userID = supabase.auth.currentUser?.id else { return }

        let updatedName = trimmedName
        guard !updatedName.isEmpty else { return }
        guard !isUpdating else { return }

        struct TribeUpdate: Encodable {
            let name: String?
            let photoURL: String?

            enum CodingKeys: String, CodingKey {
                case name
                case photoURL = "photo_url"
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if let name {
                    try container.encode(name, forKey: .name)
                }
                if let photoURL {
                    try container.encode(photoURL, forKey: .photoURL)
                }
            }
        }

        isUpdating = true
        defer { isUpdating = false }

        do {
            let uploadedURL = try await uploadTribePhotoIfNeeded(supabase: supabase, userID: userID)
            guard hasNameChange || uploadedURL != nil else { return }

            try await supabase
                .from("tribes")
                .update(
                    TribeUpdate(
                        name: hasNameChange ? updatedName : nil,
                        photoURL: uploadedURL?.absoluteString
                    )
                )
                .eq("id", value: tribeID.uuidString)
                .eq("owner_id", value: userID.uuidString)
                .execute()

            let resolvedName = hasNameChange ? updatedName : originalName
            onUpdate?(resolvedName, uploadedURL)
            dismiss()
        } catch {
            return
        }
    }
}
