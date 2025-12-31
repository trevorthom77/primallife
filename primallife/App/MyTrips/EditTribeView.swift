import SwiftUI
import PhotosUI
import Supabase

struct EditTribeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    let tribeID: UUID?
    private let originalName: String
    private let originalAbout: String
    private let originalEndDate: Date
    private let currentImageURL: URL?
    private let onUpdate: ((String, URL?, String?, Date) -> Void)?
    @State private var tribeName: String
    @State private var aboutText: String
    @State private var endDate: Date
    @State private var isUpdating = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newPhoto: UIImage?
    @State private var newPhotoData: Data?
    @State private var isShowingEndDatePicker = false

    init(
        tribeID: UUID?,
        currentName: String,
        currentImageURL: URL?,
        currentAbout: String?,
        currentEndDate: Date,
        onUpdate: ((String, URL?, String?, Date) -> Void)? = nil
    ) {
        self.tribeID = tribeID
        originalName = currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        originalAbout = currentAbout?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        originalEndDate = currentEndDate
        self.currentImageURL = currentImageURL
        self.onUpdate = onUpdate
        _tribeName = State(initialValue: currentName)
        _aboutText = State(initialValue: currentAbout ?? "")
        _endDate = State(initialValue: currentEndDate)
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
                            .frame(height: 220)
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
                        .padding(16)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .submitLabel(.done)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What?")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    TextEditor(text: $aboutText)
                        .font(.travelBody)
                        .foregroundStyle(Colors.primaryText)
                        .padding(12)
                        .frame(height: 140)
                        .scrollContentBackground(.hidden)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ending date")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Button {
                        isShowingEndDatePicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tribe end date")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(endDateText)
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.primaryText)

                                Spacer()
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
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
        .sheet(isPresented: $isShowingEndDatePicker) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Spacer()

                        Button("Done") {
                            isShowingEndDatePicker = false
                        }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                    }

                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(Colors.accent)
                }
                .padding(20)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.light)
        }
    }

    private var trimmedName: String {
        tribeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAbout: String {
        aboutText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasNameChange: Bool {
        !trimmedName.isEmpty && trimmedName != originalName
    }

    private var hasAboutChange: Bool {
        trimmedAbout != originalAbout
    }

    private var hasEndDateChange: Bool {
        !Calendar.current.isDate(originalEndDate, inSameDayAs: endDate)
    }

    private var hasNewPhoto: Bool {
        newPhotoData != nil
    }

    private var isUpdateEnabled: Bool {
        !trimmedName.isEmpty && (hasNameChange || hasNewPhoto || hasAboutChange || hasEndDateChange)
    }

    private var endDateText: String {
        endDate.formatted(date: .abbreviated, time: .omitted)
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
            let description: String?
            let endDate: String?
            let photoURL: String?

            enum CodingKeys: String, CodingKey {
                case name
                case description
                case endDate = "end_date"
                case photoURL = "photo_url"
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if let name {
                    try container.encode(name, forKey: .name)
                }
                if let description {
                    try container.encode(description, forKey: .description)
                }
                if let endDate {
                    try container.encode(endDate, forKey: .endDate)
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
            guard hasNameChange || hasAboutChange || hasEndDateChange || uploadedURL != nil else { return }
            let formattedEndDate = Self.dateFormatter.string(from: endDate)

            try await supabase
                .from("tribes")
                .update(
                    TribeUpdate(
                        name: hasNameChange ? updatedName : nil,
                        description: hasAboutChange ? trimmedAbout : nil,
                        endDate: hasEndDateChange ? formattedEndDate : nil,
                        photoURL: uploadedURL?.absoluteString
                    )
                )
                .eq("id", value: tribeID.uuidString)
                .eq("owner_id", value: userID.uuidString)
                .execute()

            let resolvedName = hasNameChange ? updatedName : originalName
            let resolvedAbout = hasAboutChange ? trimmedAbout : originalAbout
            let resolvedEndDate = hasEndDateChange ? endDate : originalEndDate
            onUpdate?(resolvedName, uploadedURL, resolvedAbout, resolvedEndDate)
            dismiss()
        } catch {
            return
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
