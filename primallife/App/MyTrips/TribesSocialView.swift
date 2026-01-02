import SwiftUI
import Supabase

struct TribesSocialView: View {
    @State private var imageURL: URL?
    @State private var title: String
    let location: String
    let flag: String
    @State private var endDate: Date
    let createdAt: Date
    let gender: String?
    @State private var aboutText: String?
    let interests: [String]
    let placeName: String?
    let tribeID: UUID?
    let createdBy: String?
    let createdByAvatarPath: String?
    let isCreator: Bool
    let onDelete: (() -> Void)?
    let onBack: (() -> Void)?
    let initialHeaderImage: Image?
    @State private var placeImageURL: URL?
    @State private var headerImage: Image?
    @State private var isShowingDeleteConfirm = false
    @Environment(\.supabaseClient) private var supabase
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    private let tribeMessages: [ChatMessage] = [
        ChatMessage(text: "Welcome to the Costa Rica crew.", time: "6:10 PM", isUser: false),
        ChatMessage(text: "Landing on the 5th, can't wait.", time: "6:12 PM", isUser: true),
        ChatMessage(text: "We're meeting at Playa Hermosa night one.", time: "6:14 PM", isUser: false),
        ChatMessage(text: "Count me in for the bonfire.", time: "6:15 PM", isUser: true)
    ]
    private let customPlaceImageNames = [
        "florida",
        "italy",
        "greece",
        "california",
        "puerto rico",
        "costa rica"
    ]

    init(
        imageURL: URL?,
        title: String,
        location: String,
        flag: String,
        endDate: Date,
        createdAt: Date,
        gender: String? = nil,
        aboutText: String? = nil,
        interests: [String] = [],
        placeName: String? = nil,
        tribeID: UUID? = nil,
        createdBy: String? = nil,
        createdByAvatarPath: String? = nil,
        isCreator: Bool = false,
        onDelete: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil,
        initialHeaderImage: Image? = nil
    ) {
        _imageURL = State(initialValue: imageURL)
        _title = State(initialValue: title)
        self.location = location
        self.flag = flag
        _endDate = State(initialValue: endDate)
        self.createdAt = createdAt
        self.gender = gender
        _aboutText = State(initialValue: aboutText)
        self.interests = interests
        self.placeName = placeName
        self.tribeID = tribeID
        self.createdBy = createdBy
        self.createdByAvatarPath = createdByAvatarPath
        self.isCreator = isCreator
        self.onDelete = onDelete
        self.onBack = onBack
        self.initialHeaderImage = initialHeaderImage
        _headerImage = State(initialValue: initialHeaderImage)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        BackButton {
                            if let onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        }

                        Spacer()

                        if isCreator {
                            NavigationLink {
                                EditTribeView(
                                    tribeID: tribeID,
                                    currentName: title,
                                    currentImageURL: imageURL,
                                    currentAbout: aboutText,
                                    currentEndDate: endDate
                                ) { updatedName, updatedImageURL, updatedAbout, updatedEndDate in
                                    title = updatedName
                                    if let updatedImageURL {
                                        imageURL = updatedImageURL
                                        headerImage = nil
                                    }
                                    aboutText = updatedAbout
                                    endDate = updatedEndDate
                                }
                            } label: {
                                Text("Edit")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.primaryText)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Colors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Colors.card)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            tribeHeaderImage
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .allowsHitTesting(false)
                        }
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: -8) {
                                Image("profile1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile2")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile3")
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

                                    Text("67+")
                                        .font(.custom(Fonts.semibold, size: 12))
                                        .foregroundStyle(Colors.primaryText)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)

                        HStack(spacing: 8) {
                            Text(flag)
                            Text(location)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.travelDetail)
                            Text(dateRangeText)
                                .font(.travelDetail)
                        }
                        .foregroundStyle(Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    NavigationLink {
                        TribesChatView(
                            title: title,
                            location: location,
                            imageURL: imageURL,
                            totalTravelers: 67,
                            messages: tribeMessages
                        )
                    } label: {
                        Text("Join")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What?")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        Text(resolvedAbout)
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 18)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who can join")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        Text(resolvedGender)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(genderAccentColor)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if !resolvedInterests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(resolvedInterests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(Colors.card)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Places")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            Spacer()

                            Button("See More") { }
                                .font(.travelDetail)
                                .foregroundStyle(Colors.accent)
                        }

                        PlaceCard(
                            imageURL: placeImageURL,
                            customImageName: customPlaceImageName,
                            name: resolvedPlaceName
                        )
                            .task {
                                if customPlaceImageName != nil {
                                    placeImageURL = nil
                                    return
                                }
                                guard !resolvedPlaceName.isEmpty else {
                                    placeImageURL = nil
                                    return
                                }
                                placeImageURL = await UnsplashService.fetchImage(for: resolvedPlaceName)
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Created By")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        HStack(spacing: 12) {
                            creatorAvatarView
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(Colors.card, lineWidth: 4)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(resolvedCreator)
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.primaryText)
                            }

                            Spacer()
                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if isCreator, tribeID != nil {
                        Button(action: {
                            isShowingDeleteConfirm = true
                        }) {
                            HStack {
                                Text("Delete Tribe")
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
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 96)
            }

            if isShowingDeleteConfirm {
                confirmationOverlay(
                    title: "Delete Tribe",
                    message: "This removes \(title) from your tribes.",
                    confirmTitle: "Delete",
                    confirmAction: {
                        isShowingDeleteConfirm = false
                        Task {
                            let didDelete = await deleteTribe()
                            guard didDelete else { return }
                            if let onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        }
                    },
                    cancelAction: {
                        isShowingDeleteConfirm = false
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

private extension TribesSocialView {
    var dateRangeText: String {
        let start = createdAt.formatted(.dateTime.month(.abbreviated).day())
        let end = endDate.formatted(.dateTime.month(.abbreviated).day().year())
        return "\(start) - \(end)"
    }

    @MainActor
    func deleteTribe() async -> Bool {
        guard let supabase,
              let tribeID,
              let userID = supabase.auth.currentUser?.id else { return false }

        do {
            try await supabase
                .from("tribes")
                .delete()
                .eq("id", value: tribeID.uuidString)
                .eq("owner_id", value: userID.uuidString)
                .execute()
            onDelete?()
            return true
        } catch {
            return false
        }
    }

    func confirmationOverlay(
        title: String,
        message: String,
        confirmTitle: String,
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
                            .background(Color.red)
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

    var creatorAvatarURL: URL? {
        if isCreator {
            return profileStore.profile?.avatarURL(using: supabase)
        }

        guard let supabase, let createdByAvatarPath else { return nil }

        return try? supabase.storage
            .from("profile-photos")
            .getPublicURL(path: createdByAvatarPath)
    }

    @ViewBuilder
    var creatorAvatarView: some View {
        if let creatorAvatarURL,
           isCreator,
           let cachedImage = profileStore.cachedAvatarImage,
           profileStore.cachedAvatarURL == creatorAvatarURL {
            cachedImage
                .resizable()
                .scaledToFill()
        } else if let creatorAvatarURL {
            AsyncImage(url: creatorAvatarURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            if isCreator {
                                profileStore.cacheAvatar(image, url: creatorAvatarURL)
                            }
                        }
                } else {
                    Colors.secondaryText.opacity(0.2)
                }
            }
        } else {
            Image("profile2")
                .resizable()
                .scaledToFill()
        }
    }

    var resolvedAbout: String {
        aboutText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var resolvedGender: String {
        gender?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var genderAccentColor: Color {
        resolvedGender.lowercased().contains("girl") ? Colors.girlsPink : Colors.accent
    }

    var resolvedInterests: [String] {
        interests
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var resolvedPlaceName: String {
        placeName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var resolvedCreator: String {
        if isCreator {
            return "You"
        }

        return createdBy?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var customPlaceImageName: String? {
        let candidates = [
            resolvedPlaceName
        ]

        for name in customPlaceImageNames {
            for candidate in candidates where candidate.localizedCaseInsensitiveContains(name) {
                return name
            }
        }

        return nil
    }

    @ViewBuilder
    var tribeHeaderImage: some View {
        if let headerImage {
            headerImage
                .resizable()
                .scaledToFill()
        } else if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            headerImage = image
                        }
                case .empty:
                    Colors.card
                default:
                    Colors.card
                }
            }
        } else {
            Colors.card
        }
    }
}

private struct PlaceCard: View {
    let imageURL: URL?
    let customImageName: String?
    let name: String

    var body: some View {
        ZStack {
            if let customImageName {
                Image(customImageName)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Colors.card
                }
            } else {
                Colors.card
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topLeading) {
            Text(name)
                .font(.travelTitle)
                .foregroundStyle(Colors.card)
                .padding(.top, 20)
                .padding(.horizontal, 16)
        }
        .clipped()
    }
}
