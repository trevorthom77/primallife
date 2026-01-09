import SwiftUI
import Supabase

private let tribeChatTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let tribeChatTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let tribeChatTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()

private let tribePlanDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let tribePlanMonthDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEEE MMM d"
    return formatter
}()

private let tribePlanMonthDayYearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEEE MMM d"
    return formatter
}()

private struct TribeMessageRow: Decodable {
    let id: UUID
    let createdAt: Date
    let tribeID: UUID
    let senderID: UUID
    let text: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case tribeID = "tribe_id"
        case senderID = "sender_id"
        case text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tribeID = try container.decode(UUID.self, forKey: .tribeID)
        senderID = try container.decode(UUID.self, forKey: .senderID)
        text = try container.decode(String.self, forKey: .text)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = tribeChatTimestampFormatterWithFractional.date(from: createdAtString)
            ?? tribeChatTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = createdAtDate
    }
}

private struct TribePlanRow: Decodable {
    let id: UUID
    let tribeID: UUID
    let creatorID: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let imagePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tribeID = "tribe_id"
        case creatorID = "creator_id"
        case title
        case startDate = "start_date"
        case endDate = "end_date"
        case imagePath = "image_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tribeID = try container.decode(UUID.self, forKey: .tribeID)
        creatorID = try container.decode(UUID.self, forKey: .creatorID)
        title = try container.decode(String.self, forKey: .title)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)

        let startDateString = try container.decode(String.self, forKey: .startDate)
        let endDateString = try container.decode(String.self, forKey: .endDate)
        guard let start = tribePlanDateFormatter.date(from: startDateString),
              let end = tribePlanDateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.startDate], debugDescription: "Invalid plan date format")
            )
        }
        startDate = start
        endDate = end
    }
}

private struct TribeMessagePayload: Encodable {
    let tribeID: UUID
    let senderID: UUID
    let text: String

    enum CodingKeys: String, CodingKey {
        case tribeID = "tribe_id"
        case senderID = "sender_id"
        case text
    }
}

private struct TribeMessageSender: Decodable {
    let id: String
    let fullName: String
    let avatarPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarPath = "avatar_url"
    }
}

private struct TribeChatMessage: Identifiable {
    let id: UUID
    let senderID: UUID
    let senderName: String
    let senderAvatarURL: URL?
    let text: String
    let time: String
    let isUser: Bool
}

private struct TribePlan: Identifiable {
    let id: UUID
    let creatorID: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let imageURL: URL?
}

private struct TribeChatCacheEntry {
    var messages: [TribeChatMessage]
    var headerImage: Image?
    var avatarImageCache: [URL: Image]
}

private enum TribeChatCache {
    static var entries: [UUID: TribeChatCacheEntry] = [:]
}

struct TribesChatView: View {
    let tribeID: UUID
    let title: String
    let location: String
    let imageURL: URL?
    let totalTravelers: Int
    @State private var headerImage: Image?
    @State private var plans: [TribePlan] = []
    @State private var selectedPlan: TribePlan?
    @State private var messages: [TribeChatMessage] = []
    @State private var avatarImageCache: [URL: Image] = [:]
    @State private var draft = ""
    @State private var shouldAnimateScroll = false
    @State private var sendFeedbackToggle = false
    @State private var realtimeChannel: RealtimeChannelV2?
    @State private var realtimeTask: Task<Void, Never>?
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase

    init(
        tribeID: UUID,
        title: String,
        location: String,
        imageURL: URL?,
        totalTravelers: Int,
        initialHeaderImage: Image? = nil
    ) {
        self.tribeID = tribeID
        self.title = title
        self.location = location
        self.imageURL = imageURL
        self.totalTravelers = totalTravelers
        let cachedEntry = TribeChatCache.entries[tribeID]
        _headerImage = State(initialValue: cachedEntry?.headerImage ?? initialHeaderImage)
        _messages = State(initialValue: cachedEntry?.messages ?? [])
        _avatarImageCache = State(initialValue: cachedEntry?.avatarImageCache ?? [:])
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if !plans.isEmpty {
                    plansRow
                }

                GeometryReader { proxy in
                    if messages.isEmpty {
                        VStack(spacing: 0) {
                            Spacer()

                            Text("No messages yet.")
                                .font(.custom(Fonts.regular, size: 16))
                                .foregroundStyle(Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                VStack(spacing: 14) {
                                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                        messageBubble(message, showsHeader: shouldShowSenderHeader(at: index))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: proxy.size.height, alignment: .bottom)
                            }
                            .scrollIndicators(.hidden)
                            .onAppear {
                                Task { @MainActor in
                                    await Task.yield()
                                    scrollToBottom(proxy: scrollProxy, animated: false)
                                }
                            }
                            .onChange(of: messages.count) { _, _ in
                                if shouldAnimateScroll {
                                    scrollToBottom(proxy: scrollProxy, animated: true)
                                    shouldAnimateScroll = false
                                } else {
                                    scrollToBottom(proxy: scrollProxy, animated: false)
                                }
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                typeBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Colors.background)
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
        .task(id: tribeID) {
            await loadPlans()
            await loadMessages()
            await startRealtime()
        }
        .onDisappear {
            Task {
                await stopRealtime()
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $selectedPlan) { plan in
            PlanMoreSheetView(
                plan: plan,
                onDeletePlan: {
                    Task {
                        await deletePlan(plan)
                    }
                }
            )
        }
    }

    private var plansRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(plans) { plan in
                    planCard(plan)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(Colors.background)
    }

    private var typeBar: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if draft.isEmpty {
                    Text("Message...")
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)
                }

                TextField("", text: $draft, axis: .vertical)
                    .font(.custom(Fonts.regular, size: 16))
                    .foregroundStyle(Colors.primaryText)
                    .tint(Colors.primaryText)
                    .focused($isInputFocused)
            }
            .padding(16)
            .background(Colors.contentview)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: {
                sendFeedbackToggle.toggle()
                Task {
                    await sendMessage()
                }
            }) {
                Text("Send")
                    .font(.custom(Fonts.semibold, size: 16))
                    .foregroundStyle(Colors.tertiaryText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: sendFeedbackToggle)
        }
    }

    private func planCard(_ plan: TribePlan) -> some View {
        let isCreator = plan.creatorID == supabase?.auth.currentUser?.id
        return VStack(alignment: .leading, spacing: 8) {
            if let imageURL = plan.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        Colors.card
                    default:
                        Colors.card
                    }
                }
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    if isCreator {
                        planMoreButton(for: plan)
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    if isCreator {
                        planMoreButton(for: plan)
                    }
                }
            }

            Text(plan.title)
                .font(.travelDetail)
                .foregroundStyle(Colors.primaryText)
                .lineLimit(1)

            Text(planDateRangeText(plan))
                .font(.badgeDetail)
                .foregroundStyle(Colors.secondaryText)
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func planMoreButton(for plan: TribePlan) -> some View {
        Button(action: {
            selectedPlan = plan
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

    private func planDateRangeText(_ plan: TribePlan) -> String {
        let calendar = Calendar(identifier: .gregorian)
        if calendar.isDate(plan.startDate, inSameDayAs: plan.endDate) {
            return tribePlanMonthDayYearFormatter.string(from: plan.startDate)
        }

        let startYear = calendar.component(.year, from: plan.startDate)
        let endYear = calendar.component(.year, from: plan.endDate)

        if startYear == endYear {
            let startText = tribePlanMonthDayFormatter.string(from: plan.startDate)
            let endText = tribePlanMonthDayYearFormatter.string(from: plan.endDate)
            return "\(startText) - \(endText)"
        }

        let startText = tribePlanMonthDayYearFormatter.string(from: plan.startDate)
        let endText = tribePlanMonthDayYearFormatter.string(from: plan.endDate)
        return "\(startText) - \(endText)"
    }

    private func messageBubble(_ message: TribeChatMessage, showsHeader: Bool) -> some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            if showsHeader, !message.senderName.isEmpty {
                HStack(spacing: 6) {
                    if !message.isUser {
                        messageAvatar(message.senderAvatarURL)
                    }

                    Text(message.senderName)
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)

                    if message.isUser {
                        messageAvatar(message.senderAvatarURL)
                    }
                }
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
            }

            Text(message.text)
                .font(.custom(Fonts.regular, size: 16))
                .foregroundStyle(message.isUser ? Colors.tertiaryText : Colors.primaryText)
                .padding(12)
                .background(message.isUser ? Colors.accent : Colors.contentview)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(message.time)
                .font(.custom(Fonts.regular, size: 12))
                .foregroundStyle(Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }

    private func shouldShowSenderHeader(at index: Int) -> Bool {
        guard messages.indices.contains(index) else { return false }
        guard index > 0 else { return true }
        return messages[index].senderID != messages[index - 1].senderID
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastID = messages.last?.id else { return }
        if animated {
            withAnimation {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    @ViewBuilder
    private func messageAvatar(_ avatarURL: URL?) -> some View {
        if let avatarURL {
            Group {
                if let cachedImage = cachedAvatarImage(for: avatarURL) {
                    cachedImage
                        .resizable()
                        .scaledToFill()
                } else {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .onAppear {
                                    cacheAvatarImage(image, for: avatarURL)
                                }
                        case .empty:
                            Color.clear
                        default:
                            Color.clear
                        }
                    }
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            BackButton {
                dismiss()
            }

            if let headerImage {
                headerImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            headerImage = image
                            cacheHeaderImage(image)
                        }
                } placeholder: {
                    Colors.card
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Colors.card
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom(Fonts.semibold, size: 18))
                    .foregroundStyle(Colors.primaryText)
                    .lineLimit(1)

                HStack(spacing: -8) {
                    Image("profile1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }

                    Image("profile2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }

                    Image("profile3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Colors.card, lineWidth: 3)
                        }

                    ZStack {
                        Circle()
                            .fill(Colors.background)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle()
                                    .stroke(Colors.card, lineWidth: 3)
                            }

                        Text("\(totalTravelers)+")
                            .font(.badgeDetail)
                            .foregroundStyle(Colors.primaryText)
                    }
                }
            }
            .frame(height: 48, alignment: .leading)

            Spacer()

            NavigationLink {
                AddPlanView(tribeID: tribeID)
            } label: {
                Text("Add Plan")
                    .font(.tripsfont)
                    .foregroundStyle(Colors.primaryText)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Colors.background)
    }

    @MainActor
    private func loadPlans() async {
        guard let supabase else { return }

        do {
            let rows: [TribePlanRow] = try await supabase
                .from("plans")
                .select("id, tribe_id, creator_id, title, start_date, end_date, image_path")
                .eq("tribe_id", value: tribeID.uuidString)
                .order("start_date", ascending: true)
                .execute()
                .value

            let newPlans = rows.map { row -> TribePlan in
                let imageURL: URL?
                if let imagePath = row.imagePath, !imagePath.isEmpty {
                    imageURL = try? supabase.storage
                        .from("plan-photos")
                        .getPublicURL(path: imagePath)
                } else {
                    imageURL = nil
                }

                return TribePlan(
                    id: row.id,
                    creatorID: row.creatorID,
                    title: row.title,
                    startDate: row.startDate,
                    endDate: row.endDate,
                    imageURL: imageURL
                )
            }

            plans = newPlans
        } catch {
            return
        }
    }

    @MainActor
    private func deletePlan(_ plan: TribePlan) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }

        do {
            try await supabase
                .from("plans")
                .delete()
                .eq("id", value: plan.id.uuidString)
                .eq("creator_id", value: userID.uuidString)
                .execute()
            await loadPlans()
        } catch {
            return
        }
    }

    @MainActor
    private func loadMessages() async {
        guard let supabase else { return }

        do {
            let rows: [TribeMessageRow] = try await supabase
                .from("tribe_messages")
                .select()
                .eq("tribe_id", value: tribeID.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value

            var senderNames: [String: String] = [:]
            var senderAvatarURLs: [String: URL] = [:]
            let senderIDs = Set(rows.map { $0.senderID.uuidString.lowercased() })
            if !senderIDs.isEmpty {
                let senders: [TribeMessageSender] = try await supabase
                    .from("onboarding")
                    .select("id, full_name, avatar_url")
                    .in("id", values: Array(senderIDs))
                    .execute()
                    .value
                senderNames = Dictionary(
                    uniqueKeysWithValues: senders.map { ($0.id.lowercased(), $0.fullName) }
                )
                senderAvatarURLs = Dictionary(
                    uniqueKeysWithValues: senders.compactMap { sender in
                        guard let avatarPath = sender.avatarPath,
                              !avatarPath.isEmpty,
                              let avatarURL = try? supabase.storage
                                .from("profile-photos")
                                .getPublicURL(path: avatarPath) else {
                            return nil
                        }
                        return (sender.id.lowercased(), avatarURL)
                    }
                )
            }

            let currentUserID = supabase.auth.currentUser?.id
            let newMessages = rows.map { row in
                let senderKey = row.senderID.uuidString.lowercased()
                return TribeChatMessage(
                    id: row.id,
                    senderID: row.senderID,
                    senderName: senderNames[senderKey] ?? "",
                    senderAvatarURL: senderAvatarURLs[senderKey],
                    text: row.text,
                    time: tribeChatTimeFormatter.string(from: row.createdAt),
                    isUser: row.senderID == currentUserID
                )
            }
            messages = newMessages
            cacheMessages(newMessages)
        } catch {
        }
    }

    @MainActor
    private func startRealtime() async {
        guard let supabase else { return }

        await stopRealtime()

        let channel = supabase.channel("tribe-messages-\(tribeID.uuidString)")
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "tribe_messages",
            filter: .eq("tribe_id", value: tribeID)
        )

        do {
            try await channel.subscribeWithError()
        } catch {
            return
        }

        realtimeChannel = channel
        realtimeTask = Task { @MainActor in
            for await _ in insertions {
                await loadMessages()
            }
        }
    }

    @MainActor
    private func stopRealtime() async {
        realtimeTask?.cancel()
        realtimeTask = nil

        if let supabase, let realtimeChannel {
            await supabase.removeChannel(realtimeChannel)
        }

        realtimeChannel = nil
    }

    @MainActor
    private func sendMessage() async {
        let trimmedMessage = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty,
              let supabase,
              let userID = supabase.auth.currentUser?.id else { return }

        shouldAnimateScroll = true
        let payload = TribeMessagePayload(
            tribeID: tribeID,
            senderID: userID,
            text: trimmedMessage
        )

        do {
            try await supabase
                .from("tribe_messages")
                .insert(payload)
                .execute()
            draft = ""
            await loadMessages()
        } catch {
            shouldAnimateScroll = false
        }
    }

    private func cacheMessages(_ newMessages: [TribeChatMessage]) {
        var entry = TribeChatCache.entries[tribeID]
            ?? TribeChatCacheEntry(messages: [], headerImage: nil, avatarImageCache: [:])
        entry.messages = newMessages
        TribeChatCache.entries[tribeID] = entry
    }

    private func cacheHeaderImage(_ image: Image) {
        var entry = TribeChatCache.entries[tribeID]
            ?? TribeChatCacheEntry(
                messages: messages,
                headerImage: nil,
                avatarImageCache: avatarImageCache
            )
        entry.headerImage = image
        TribeChatCache.entries[tribeID] = entry
    }

    private func cachedAvatarImage(for url: URL) -> Image? {
        avatarImageCache[url]
    }

    private func cacheAvatarImage(_ image: Image, for url: URL) {
        avatarImageCache[url] = image
        var entry = TribeChatCache.entries[tribeID]
            ?? TribeChatCacheEntry(
                messages: messages,
                headerImage: headerImage,
                avatarImageCache: [:]
            )
        entry.avatarImageCache[url] = image
        TribeChatCache.entries[tribeID] = entry
    }
}

private struct PlanMoreSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirm = false
    let plan: TribePlan
    let onDeletePlan: () -> Void

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
                    Text("Delete Plan")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.secondaryText)

                    Text("This removes \(plan.title) from the plans list.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)

                    Button(action: {
                        isShowingDeleteConfirm = true
                    }) {
                        HStack {
                            Text("Delete Plan")
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
                    title: "Delete Plan",
                    message: "This removes \(plan.title) from the plans list.",
                    confirmTitle: "Delete",
                    isDestructive: true,
                    confirmAction: {
                        isShowingDeleteConfirm = false
                        onDeletePlan()
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
