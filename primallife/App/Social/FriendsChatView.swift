//
//  FriendsChatView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import Supabase

private let friendChatTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let friendChatTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let friendChatTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()

private struct FriendMessageRow: Decodable {
    let id: UUID
    let userID: UUID
    let friendID: UUID
    let senderID: UUID
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case friendID = "friend_id"
        case senderID = "sender_id"
        case text
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        friendID = try container.decode(UUID.self, forKey: .friendID)
        senderID = try container.decode(UUID.self, forKey: .senderID)
        text = try container.decode(String.self, forKey: .text)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = friendChatTimestampFormatterWithFractional.date(from: createdAtString)
            ?? friendChatTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = createdAtDate
    }
}

private struct FriendMessagePayload: Encodable {
    let userID: UUID
    let friendID: UUID
    let senderID: UUID
    let text: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case friendID = "friend_id"
        case senderID = "sender_id"
        case text
    }
}

private struct FriendChatMessage: Identifiable {
    let id: UUID
    let senderID: UUID
    let text: String
    let time: String
    let isUser: Bool
}

private struct FriendsChatCacheEntry {
    var messages: [FriendChatMessage]
    var friendAvatarURL: URL?
    var friendAvatarImage: Image?
    var friendName: String?
    var currentUserAvatarURL: URL?
    var currentUserAvatarImage: Image?
    var currentUserName: String?
}

private enum FriendsChatCache {
    static var entries: [UUID: FriendsChatCacheEntry] = [:]
}

struct FriendsChatView: View {
    let friendID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var messages: [FriendChatMessage] = []
    @State private var friendAvatarURL: URL?
    @State private var friendAvatarImage: Image?
    @State private var friendName: String?
    @State private var currentUserAvatarURL: URL?
    @State private var currentUserAvatarImage: Image?
    @State private var currentUserName: String?
    @State private var draft = ""
    @State private var shouldAnimateScroll = false
    @State private var sendFeedbackToggle = false
    @State private var outgoingRealtimeChannel: RealtimeChannelV2?
    @State private var incomingRealtimeChannel: RealtimeChannelV2?
    @State private var outgoingRealtimeTask: Task<Void, Never>?
    @State private var incomingRealtimeTask: Task<Void, Never>?
    @FocusState private var isInputFocused: Bool

    init(friendID: UUID) {
        self.friendID = friendID
        let cachedEntry = FriendsChatCache.entries[friendID]
        _messages = State(initialValue: cachedEntry?.messages ?? [])
        _friendAvatarURL = State(initialValue: cachedEntry?.friendAvatarURL)
        _friendAvatarImage = State(initialValue: cachedEntry?.friendAvatarImage)
        _friendName = State(initialValue: cachedEntry?.friendName)
        _currentUserAvatarURL = State(initialValue: cachedEntry?.currentUserAvatarURL)
        _currentUserAvatarImage = State(initialValue: cachedEntry?.currentUserAvatarImage)
        _currentUserName = State(initialValue: cachedEntry?.currentUserName)
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    BackButton {
                        dismiss()
                    }

                    friendAvatar

                    if let friendName {
                        Text(friendName)
                            .font(.custom(Fonts.semibold, size: 18))
                            .foregroundStyle(Colors.primaryText)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Colors.background)

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
        .navigationBarBackButtonHidden(true)
        .task(id: friendID) {
            await loadFriendProfile()
            await loadCurrentUserProfile()
            await loadMessages()
            await startRealtime()
        }
        .onDisappear {
            Task {
                await stopRealtime()
            }
        }
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

    private func messageBubble(_ message: FriendChatMessage, showsHeader: Bool) -> some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            if showsHeader,
               let headerName = message.isUser ? currentUserName : friendName,
               !headerName.isEmpty {
                HStack(spacing: 6) {
                    if !message.isUser {
                        friendMessageAvatar
                    }

                    Text(headerName)
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)

                    if message.isUser {
                        currentUserMessageAvatar
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
    private var friendAvatar: some View {
        if let friendAvatarImage {
            friendAvatarImage
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let friendAvatarURL {
            AsyncImage(url: friendAvatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .onAppear {
                        if friendAvatarImage == nil {
                            friendAvatarImage = image
                            cacheFriendAvatarImage(image)
                        }
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
    }

    @ViewBuilder
    private var friendMessageAvatar: some View {
        if let friendAvatarImage {
            friendAvatarImage
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else if let friendAvatarURL {
            AsyncImage(url: friendAvatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .onAppear {
                        if friendAvatarImage == nil {
                            friendAvatarImage = image
                            cacheFriendAvatarImage(image)
                        }
                    }
            } placeholder: {
                Colors.card
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var currentUserMessageAvatar: some View {
        if let currentUserAvatarImage {
            currentUserAvatarImage
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else if let currentUserAvatarURL {
            AsyncImage(url: currentUserAvatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .onAppear {
                        if currentUserAvatarImage == nil {
                            currentUserAvatarImage = image
                            cacheCurrentUserAvatarImage(image)
                        }
                    }
            } placeholder: {
                Colors.card
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        }
    }

    @MainActor
    private func loadFriendProfile() async {
        guard let supabase else { return }

        do {
            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .eq("id", value: friendID.uuidString)
                .limit(1)
                .execute()
                .value

            friendAvatarURL = profiles.first?.avatarURL(using: supabase)
            friendName = profiles.first?.fullName
            cacheFriendProfile(avatarURL: friendAvatarURL, name: friendName)
        } catch {
            return
        }
    }

    @MainActor
    private func loadCurrentUserProfile() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id else { return }

        do {
            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .eq("id", value: currentUserID.uuidString)
                .limit(1)
                .execute()
                .value

            currentUserAvatarURL = profiles.first?.avatarURL(using: supabase)
            currentUserName = profiles.first?.fullName
            cacheCurrentUserProfile(avatarURL: currentUserAvatarURL, name: currentUserName)
        } catch {
            return
        }
    }

    @MainActor
    private func loadMessages() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id else { return }

        do {
            let sentRows: [FriendMessageRow] = try await supabase
                .from("friend_messages")
                .select()
                .eq("user_id", value: currentUserID.uuidString)
                .eq("friend_id", value: friendID.uuidString)
                .execute()
                .value

            let receivedRows: [FriendMessageRow] = try await supabase
                .from("friend_messages")
                .select()
                .eq("user_id", value: friendID.uuidString)
                .eq("friend_id", value: currentUserID.uuidString)
                .execute()
                .value

            let sortedRows = (sentRows + receivedRows).sorted { $0.createdAt < $1.createdAt }
            let newMessages = sortedRows.map { row in
                FriendChatMessage(
                    id: row.id,
                    senderID: row.senderID,
                    text: row.text,
                    time: friendChatTimeFormatter.string(from: row.createdAt),
                    isUser: row.senderID == currentUserID
                )
            }
            messages = newMessages
            cacheMessages(newMessages)
        } catch {
            return
        }
    }

    @MainActor
    private func startRealtime() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id else { return }

        await stopRealtime()

        let outgoingChannel = supabase.channel("friend-messages-\(currentUserID.uuidString)-\(friendID.uuidString)-out")
        let outgoingInsertions = outgoingChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "friend_messages",
            filter: .eq("user_id", value: currentUserID)
        )

        let incomingChannel = supabase.channel("friend-messages-\(currentUserID.uuidString)-\(friendID.uuidString)-in")
        let incomingInsertions = incomingChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "friend_messages",
            filter: .eq("user_id", value: friendID)
        )

        do {
            try await outgoingChannel.subscribeWithError()
            try await incomingChannel.subscribeWithError()
        } catch {
            return
        }

        outgoingRealtimeChannel = outgoingChannel
        incomingRealtimeChannel = incomingChannel
        outgoingRealtimeTask = Task { @MainActor in
            for await _ in outgoingInsertions {
                await loadMessages()
            }
        }
        incomingRealtimeTask = Task { @MainActor in
            for await _ in incomingInsertions {
                await loadMessages()
            }
        }
    }

    @MainActor
    private func stopRealtime() async {
        outgoingRealtimeTask?.cancel()
        outgoingRealtimeTask = nil
        incomingRealtimeTask?.cancel()
        incomingRealtimeTask = nil

        if let supabase, let outgoingRealtimeChannel {
            await supabase.removeChannel(outgoingRealtimeChannel)
        }

        if let supabase, let incomingRealtimeChannel {
            await supabase.removeChannel(incomingRealtimeChannel)
        }

        outgoingRealtimeChannel = nil
        incomingRealtimeChannel = nil
    }

    @MainActor
    private func sendMessage() async {
        let trimmedMessage = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty,
              let supabase,
              let currentUserID = supabase.auth.currentUser?.id else { return }

        shouldAnimateScroll = true
        let payload = FriendMessagePayload(
            userID: currentUserID,
            friendID: friendID,
            senderID: currentUserID,
            text: trimmedMessage
        )

        do {
            try await supabase
                .from("friend_messages")
                .insert(payload)
                .execute()
            draft = ""
            await loadMessages()
        } catch {
            shouldAnimateScroll = false
            return
        }
    }

    private func cacheEntry() -> FriendsChatCacheEntry {
        FriendsChatCache.entries[friendID] ?? FriendsChatCacheEntry(
            messages: messages,
            friendAvatarURL: friendAvatarURL,
            friendAvatarImage: friendAvatarImage,
            friendName: friendName,
            currentUserAvatarURL: currentUserAvatarURL,
            currentUserAvatarImage: currentUserAvatarImage,
            currentUserName: currentUserName
        )
    }

    private func cacheMessages(_ newMessages: [FriendChatMessage]) {
        var entry = cacheEntry()
        entry.messages = newMessages
        FriendsChatCache.entries[friendID] = entry
    }

    private func cacheFriendProfile(avatarURL: URL?, name: String?) {
        var entry = cacheEntry()
        entry.friendAvatarURL = avatarURL
        entry.friendName = name
        FriendsChatCache.entries[friendID] = entry
    }

    private func cacheFriendAvatarImage(_ image: Image) {
        var entry = cacheEntry()
        entry.friendAvatarImage = image
        FriendsChatCache.entries[friendID] = entry
    }

    private func cacheCurrentUserProfile(avatarURL: URL?, name: String?) {
        var entry = cacheEntry()
        entry.currentUserAvatarURL = avatarURL
        entry.currentUserName = name
        FriendsChatCache.entries[friendID] = entry
    }

    private func cacheCurrentUserAvatarImage(_ image: Image) {
        var entry = cacheEntry()
        entry.currentUserAvatarImage = image
        FriendsChatCache.entries[friendID] = entry
    }
}
