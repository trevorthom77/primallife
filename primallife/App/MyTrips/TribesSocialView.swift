import SwiftUI
import Supabase

private let tribesSocialBirthdayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let tribesSocialBirthdayTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let tribesSocialBirthdayTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

struct TribesSocialView: View {
    @State private var imageURL: URL?
    @State private var title: String
    let location: String
    let flag: String
    @State private var endDate: Date
    let minAge: Int?
    let maxAge: Int?
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
    @State private var isShowingLeaveConfirm = false
    @State private var isShowingMembersSheet = false
    @State private var isShowingMoreSheet = false
    @State private var shouldShowLeaveConfirm = false
    @State private var isShowingReport = false
    @State private var reportUserID: UUID?
    @State private var totalTravelers = 0
    @State private var shouldNavigateToChat = false
    @State private var hasJoinedTribe = false
    @State private var isJoiningTribe = false
    @State private var currentUserGender: String?
    @State private var members: [TribeMember] = []
    @Environment(\.supabaseClient) private var supabase
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    private let customPlaceImageNames = [
        "italy",
        "greece",
        "puerto rico",
        "costa rica",
        "australia",
        "jamaica",
        "switzerland"
    ]

    init(
        imageURL: URL?,
        title: String,
        location: String,
        flag: String,
        endDate: Date,
        minAge: Int?,
        maxAge: Int?,
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
        self.minAge = minAge
        self.maxAge = maxAge
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
        _totalTravelers = State(initialValue: Self.cachedMemberCount(for: tribeID) ?? 0)
        _hasJoinedTribe = State(initialValue: Self.cachedJoinStatus(for: tribeID))
        _members = State(initialValue: Self.cachedMembers(for: tribeID) ?? [])
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
                        } else {
                            Button(action: {
                                isShowingMoreSheet = true
                            }) {
                                Image(systemName: "ellipsis")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.primaryText)
                                    .frame(width: 36, height: 36)
                                    .background(Colors.card.opacity(0.9))
                                    .clipShape(Circle())
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
                            Button(action: {
                                isShowingMembersSheet = true
                            }) {
                                HStack(spacing: -8) {
                                    ForEach(members.prefix(3)) { member in
                                        ZStack {
                                            if let avatarURL = member.avatarURL {
                                                AsyncImage(url: avatarURL) { phase in
                                                    if let image = phase.image {
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                    } else {
                                                        Color.clear
                                                    }
                                                }
                                            } else {
                                                Color.clear
                                            }
                                        }
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                        .overlay {
                                            Circle()
                                                .stroke(Colors.card, lineWidth: 3)
                                        }
                                    }

                                    ZStack {
                                        Circle()
                                            .fill(Colors.background)
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        Text("\(totalTravelers)+")
                                            .font(.custom(Fonts.semibold, size: 12))
                                            .foregroundStyle(Colors.primaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
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

                    if let joinRestrictionText {
                        Text(joinRestrictionText)
                            .font(.travelDetail)
                            .foregroundStyle(joinRestrictionColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Button {
                            if hasJoinedTribe {
                                shouldNavigateToChat = true
                                return
                            }
                            guard !isJoiningTribe else { return }
                            isJoiningTribe = true
                            Task {
                                let didJoin = await joinTribe()
                                if didJoin {
                                    hasJoinedTribe = true
                                    shouldNavigateToChat = true
                                }
                                isJoiningTribe = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(hasJoinedTribe ? "View Chat" : "Join")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.tertiaryText)

                                if isJoiningTribe {
                                    ProgressView()
                                        .tint(Colors.tertiaryText)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }

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

                        HStack(spacing: 8) {
                            Text(resolvedGender)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.tertiaryText)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(genderAccentColor)
                                .clipShape(Capsule())

                            Text(resolvedAgeRange)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.tertiaryText)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(genderAccentColor)
                                .clipShape(Capsule())
                        }
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
                        Text("Places")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

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

            if isShowingLeaveConfirm {
                confirmationOverlay(
                    title: "Leave Tribe",
                    message: "This removes you from \(title).",
                    confirmTitle: "Leave",
                    confirmAction: {
                        isShowingLeaveConfirm = false
                    },
                    cancelAction: {
                        isShowingLeaveConfirm = false
                    }
                )
            }
        }
        .task {
            await loadJoinStatus()
            await loadCurrentUserGender()
            await loadMemberCount()
            await loadMembers()
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $shouldNavigateToChat) {
            if let tribeID {
                TribesChatView(
                    tribeID: tribeID,
                    title: title,
                    location: location,
                    imageURL: imageURL,
                    totalTravelers: 0,
                    initialHeaderImage: headerImage ?? initialHeaderImage
                )
            } else {
                EmptyView()
            }
        }
        .navigationDestination(isPresented: $isShowingReport) {
            ReportView(reportedUserID: reportUserID, showsBlockPrompt: false)
        }
        .sheet(isPresented: $isShowingMembersSheet) {
            membersSheet
        }
        .sheet(isPresented: $isShowingMoreSheet, onDismiss: {
            if shouldShowLeaveConfirm {
                shouldShowLeaveConfirm = false
                isShowingLeaveConfirm = true
            }
        }) {
            TribesSocialMoreSheetView(
                isCreator: isCreator,
                leaveAction: {
                    shouldShowLeaveConfirm = true
                    isShowingMoreSheet = false
                },
                reportAction: {
                    isShowingMoreSheet = false
                    Task { @MainActor in
                        guard await resolveReportUserID() != nil else { return }
                        isShowingReport = true
                    }
                }
            )
        }
    }
}

private struct TribeJoinPayload: Encodable {
    let id: UUID
    let tribeID: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case tribeID = "tribe_id"
    }
}

private struct TribeJoinRecord: Decodable {
    let id: UUID
}

private struct TribeMemberRow: Decodable {
    let id: UUID
}

private struct TribeMemberProfileRow: Decodable {
    let id: UUID
    let fullName: String
    let avatarPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarPath = "avatar_url"
    }
}

private struct TribeMember: Identifiable {
    let id: UUID
    let fullName: String
    let avatarURL: URL?
}

private struct OnboardingGenderRow: Decodable {
    let gender: String?
}

private struct OnboardingBirthdayRow: Decodable {
    let birthday: String?
}

private enum TribeSocialCache {
    static var memberCounts: [UUID: Int] = [:]
    static var members: [UUID: [TribeMember]] = [:]
}

private extension TribesSocialView {
    static func cachedMemberCount(for tribeID: UUID?) -> Int? {
        guard let tribeID else { return nil }
        return TribeSocialCache.memberCounts[tribeID]
    }

    func cacheMemberCount(_ count: Int) {
        guard let tribeID else { return }
        TribeSocialCache.memberCounts[tribeID] = count
    }

    static func cachedMembers(for tribeID: UUID?) -> [TribeMember]? {
        guard let tribeID else { return nil }
        return TribeSocialCache.members[tribeID]
    }

    func cacheMembers(_ members: [TribeMember]) {
        guard let tribeID else { return }
        TribeSocialCache.members[tribeID] = members
    }

    static func cachedJoinStatus(for tribeID: UUID?) -> Bool {
        guard let tribeID else { return false }
        return UserDefaults.standard.bool(forKey: joinCacheKey(for: tribeID))
    }

    func cacheJoinStatus(_ joined: Bool) {
        guard let tribeID else { return }
        UserDefaults.standard.set(joined, forKey: Self.joinCacheKey(for: tribeID))
    }

    static func joinCacheKey(for tribeID: UUID) -> String {
        "tribeJoinStatus.\(tribeID.uuidString)"
    }

    static func genderCacheKey(for userID: UUID) -> String {
        "userGender.\(userID.uuidString)"
    }

    func cachedUserGender(for userID: UUID?) -> String? {
        guard let userID else { return nil }
        return UserDefaults.standard.string(forKey: Self.genderCacheKey(for: userID))
    }

    func cacheUserGender(_ gender: String, for userID: UUID) {
        UserDefaults.standard.set(gender, forKey: Self.genderCacheKey(for: userID))
    }

    var dateRangeText: String {
        let start = createdAt.formatted(.dateTime.month(.abbreviated).day())
        let end = endDate.formatted(.dateTime.month(.abbreviated).day().year())
        return "\(start) - \(end)"
    }

    var membersSheet: some View {
        NavigationStack {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                if members.isEmpty {
                    Text("No travelers yet")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(members) { member in
                                memberRow(member)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .task {
                await loadMembers()
            }
        }
    }

    func memberRow(_ member: TribeMember) -> some View {
        NavigationLink {
            OthersProfileView(userID: member.id)
        } label: {
            HStack(spacing: 12) {
                if let avatarURL = member.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Color.clear
                        .frame(width: 36, height: 36)
                }

                Text(member.fullName)
                    .font(.travelBodySemibold)
                    .foregroundStyle(Colors.primaryText)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    func loadMembers() async {
        guard let supabase, let tribeID else { return }

        do {
            let joinRows: [TribeMemberRow] = try await supabase
                .from("tribes_join")
                .select("id")
                .eq("tribe_id", value: tribeID.uuidString)
                .execute()
                .value

            let memberIDs = Array(Set(joinRows.map { $0.id }))
            guard !memberIDs.isEmpty else {
                members = []
                cacheMembers([])
                return
            }

            let rows: [TribeMemberProfileRow] = try await supabase
                .from("onboarding")
                .select("id, full_name, avatar_url")
                .in("id", values: memberIDs.map { $0.uuidString })
                .execute()
                .value

            let newMembers = rows.map { row -> TribeMember in
                let avatarURL: URL?
                if let avatarPath = row.avatarPath, !avatarPath.isEmpty {
                    avatarURL = try? supabase.storage
                        .from("profile-photos")
                        .getPublicURL(path: avatarPath)
                } else {
                    avatarURL = nil
                }

                return TribeMember(
                    id: row.id,
                    fullName: row.fullName,
                    avatarURL: avatarURL
                )
            }

            members = newMembers
            cacheMembers(newMembers)
        } catch {
            return
        }
    }

    @MainActor
    func joinTribe() async -> Bool {
        guard let supabase,
              let tribeID,
              let userID = supabase.auth.currentUser?.id else { return false }

        guard await isAllowedToJoin(tribeGender: resolvedGender, userID: userID, supabase: supabase) else {
            return false
        }

        let payload = TribeJoinPayload(id: userID, tribeID: tribeID)

        do {
            try await supabase
                .from("tribes_join")
                .insert(payload)
                .execute()
            cacheJoinStatus(true)
            return true
        } catch {
            return false
        }
    }

    func isAllowedToJoin(tribeGender: String, userID: UUID, supabase: SupabaseClient) async -> Bool {
        let normalizedTribeGender = tribeGender
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalizedTribeGender.contains("girl") {
            guard await userGender(for: userID, supabase: supabase) == "female" else {
                return false
            }
        }

        if normalizedTribeGender.contains("boy") {
            guard await userGender(for: userID, supabase: supabase) == "male" else {
                return false
            }
        }

        if minAge != nil || maxAge != nil {
            guard let age = await userAge(for: userID, supabase: supabase) else {
                return false
            }
            if let minAge, age < minAge {
                return false
            }
            if let maxAge, age > maxAge {
                return false
            }
        }

        return true
    }

    func userGender(for userID: UUID, supabase: SupabaseClient) async -> String? {
        if let cachedGender = profileStore.profile?.gender?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
           !cachedGender.isEmpty {
            return cachedGender
        }

        do {
            let rows: [OnboardingGenderRow] = try await supabase
                .from("onboarding")
                .select("gender")
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value
            return rows.first?.gender?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        } catch {
            return nil
        }
    }

    func userAge(for userID: UUID, supabase: SupabaseClient) async -> Int? {
        if let cachedAge = age(from: profileStore.profile?.birthday) {
            return cachedAge
        }

        do {
            let rows: [OnboardingBirthdayRow] = try await supabase
                .from("onboarding")
                .select("birthday")
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value
            return age(from: rows.first?.birthday)
        } catch {
            return nil
        }
    }

    func age(from birthday: String?) -> Int? {
        guard let birthday, !birthday.isEmpty else { return nil }

        let birthDate = tribesSocialBirthdayTimestampFormatterWithFractional.date(from: birthday)
            ?? tribesSocialBirthdayTimestampFormatter.date(from: birthday)
            ?? tribesSocialBirthdayDateFormatter.date(from: birthday)
        guard let birthDate else { return nil }

        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    @MainActor
    func loadJoinStatus() async {
        guard let supabase,
              let tribeID,
              let userID = supabase.auth.currentUser?.id else { return }

        do {
            let rows: [TribeJoinRecord] = try await supabase
                .from("tribes_join")
                .select("id")
                .eq("id", value: userID.uuidString)
                .eq("tribe_id", value: tribeID.uuidString)
                .execute()
                .value
            hasJoinedTribe = !rows.isEmpty
            cacheJoinStatus(hasJoinedTribe)
        } catch {
            hasJoinedTribe = false
            cacheJoinStatus(false)
        }
    }

    @MainActor
    func loadCurrentUserGender() async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id else { return }
        if let cachedGender = cachedUserGender(for: userID) {
            currentUserGender = cachedGender
        }
        if let freshGender = await userGender(for: userID, supabase: supabase) {
            currentUserGender = freshGender
            cacheUserGender(freshGender, for: userID)
        }
    }

    @MainActor
    func loadMemberCount() async {
        guard let supabase, let tribeID else { return }

        do {
            let rows: [TribeMemberRow] = try await supabase
                .from("tribes_join")
                .select("id")
                .eq("tribe_id", value: tribeID.uuidString)
                .execute()
                .value
            totalTravelers = rows.count
            cacheMemberCount(rows.count)
        } catch {
            return
        }
    }

    @MainActor
    func resolveReportUserID() async -> UUID? {
        if let reportUserID {
            return reportUserID
        }
        guard let tribeID else { return nil }
        reportUserID = tribeID
        return tribeID
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

    var resolvedAgeRange: String {
        guard let minAge, let maxAge else { return "" }
        if minAge == maxAge {
            return "\(minAge)"
        }
        return "\(minAge)-\(maxAge)"
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

    var joinRestrictionText: String? {
        guard !hasJoinedTribe else { return nil }
        let restrictions = [genderRestrictionText, ageRestrictionText].compactMap { $0 }
        guard !restrictions.isEmpty else { return nil }
        return restrictions.joined(separator: " | ")
    }

    var genderRestrictionText: String? {
        let normalizedTribeGender = resolvedGender
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let normalizedUserGender = resolvedUserGender?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !normalizedUserGender.isEmpty else {
            return nil
        }

        if normalizedTribeGender.contains("girl"), normalizedUserGender != "female" {
            return "Girls Only"
        }

        if normalizedTribeGender.contains("boy"), normalizedUserGender != "male" {
            return "Boys Only"
        }

        return nil
    }

    var ageRestrictionText: String? {
        guard let restrictionLabel = ageRestrictionLabel else { return nil }
        guard let userAge = resolvedUserAge else { return nil }

        if let minAge, userAge < minAge {
            return restrictionLabel
        }

        if let maxAge, userAge > maxAge {
            return restrictionLabel
        }

        return nil
    }

    var ageRestrictionLabel: String? {
        guard minAge != nil || maxAge != nil else { return nil }

        if let minAge, let maxAge {
            if minAge == maxAge {
                return "Age \(minAge) Only"
            }
            return "Ages \(minAge)-\(maxAge)"
        }

        if let minAge {
            return "Ages \(minAge)+"
        }

        if let maxAge {
            return "Ages \(maxAge) and under"
        }

        return nil
    }

    var resolvedUserGender: String? {
        if let currentUserGender, !currentUserGender.isEmpty {
            return currentUserGender
        }

        return cachedUserGender(for: supabase?.auth.currentUser?.id)
    }

    var resolvedUserAge: Int? {
        age(from: profileStore.profile?.birthday)
    }

    var joinRestrictionColor: Color {
        let normalizedTribeGender = resolvedGender
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalizedTribeGender.contains("girl") {
            return Colors.girlsPink
        }

        if normalizedTribeGender.contains("boy") {
            return Colors.accent
        }

        return Colors.secondaryText
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

private struct TribesSocialMoreSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let isCreator: Bool
    let leaveAction: () -> Void
    let reportAction: () -> Void

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
                    if !isCreator {
                        Button(action: leaveAction) {
                            HStack {
                                Text("Leave Tribe")
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

                    Button(action: reportAction) {
                        HStack {
                            Text("Report")
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
        .presentationDetents([.height(320)])
        .presentationBackground(Colors.background)
        .presentationDragIndicator(.hidden)
    }
}
