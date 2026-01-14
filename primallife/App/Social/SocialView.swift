//
//  MessagesView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/18/25.
//

import SwiftUI
import Supabase

private let socialChatTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let socialChatTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let socialChatTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()

private let socialPlanDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let socialPlanMonthDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEEE MMM d"
    return formatter
}()

struct MessagesView: View {
    @State private var isShowingBell = false
    @State private var joinedTribeChats: [TribeChatPreview] = []
    @State private var friendChats: [FriendChatPreview] = []
    @State private var activePlans: [SocialPlan] = []
    @State private var isLoadingTribeChats = false
    @State private var friends: [UserProfile] = []
    @State private var notificationCount = 0
    @Environment(\.supabaseClient) private var supabase
    
    private var notificationBadgeText: String? {
        guard notificationCount > 0 else { return nil }
        return notificationCount > 9 ? "9+" : "\(notificationCount)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Chats")
                                        .font(.travelTitle)
                                        .foregroundStyle(Colors.primaryText)
                                }

                                if !joinedTribeChats.isEmpty || !friendChats.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(joinedTribeChats) { chat in
                                            NavigationLink {
                                                TribesChatView(
                                                    tribeID: chat.id,
                                                    title: chat.name,
                                                    location: chat.destination,
                                                    imageURL: chat.photoURL,
                                                    totalTravelers: chat.memberCount,
                                                    initialHeaderImage: nil
                                                )
                                            } label: {
                                                tribeChatRow(chat)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        ForEach(friendChats) { chat in
                                            NavigationLink {
                                                FriendsChatView(friendID: chat.id)
                                            } label: {
                                                friendChatRow(chat)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                } else {
                                    Text("No chats yet")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Plans")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)

                                if !activePlans.isEmpty {
                                    plansRow
                                } else {
                                    Text("No plans yet")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Friends")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)

                                if !friends.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(friends) { friend in
                                            NavigationLink {
                                                OthersProfileView(userID: friend.id)
                                            } label: {
                                                friendCard(friend)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                } else {
                                    Text("No friends yet")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                            }
                            
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingBell) {
                BellView()
            }
            .task {
                await loadJoinedTribeChats()
                await loadFriends()
                await loadFriendChats()
                await loadNotificationCount()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Social")
                .font(.customTitle)
                .foregroundStyle(Colors.primaryText)
            
            Spacer()
            
            Button(action: {
                isShowingBell = true
            }) {
                ZStack {
                    Circle()
                        .fill(Colors.card)
                        .frame(width: 44, height: 44)
                    
                    Image("bell")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Colors.primaryText)
                }
                .overlay(alignment: .topTrailing) {
                    if let badgeText = notificationBadgeText {
                        Text(badgeText)
                            .font(.badgeDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(width: 20, height: 20)
                            .background(Colors.accent)
                            .clipShape(Circle())
                            .padding(2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Colors.background)
    }
    
    private func tribeChatRow(_ chat: TribeChatPreview) -> some View {
        HStack(spacing: 12) {
            tribeChatImage(for: chat)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(chat.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                if !chat.lastMessage.isEmpty {
                    Text(chat.lastMessage)
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !chat.lastMessageTime.isEmpty {
                Text(chat.lastMessageTime)
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
            }
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func friendChatRow(_ chat: FriendChatPreview) -> some View {
        HStack(spacing: 12) {
            friendAvatar(for: chat.friend)
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(chat.friend.fullName)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                if !chat.lastMessage.isEmpty {
                    Text(chat.lastMessage)
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !chat.lastMessageTime.isEmpty {
                Text(chat.lastMessageTime)
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
            }
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var plansRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(activePlans) { plan in
                    planCard(plan)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func planCard(_ plan: SocialPlan) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let imageURL = plan.imageURL {
                planImage(for: imageURL)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                    .lineLimit(1)

                Text(planDateRangeText(plan))
                    .font(.badgeDetail)
                    .foregroundStyle(Colors.secondaryText)

                if !plan.tribeName.isEmpty {
                    Text(plan.tribeName)
                        .font(.badgeDetail)
                        .foregroundStyle(Colors.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Colors.contentview)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .frame(width: 240, alignment: .leading)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func planImage(for url: URL) -> some View {
        AsyncImage(url: url) { phase in
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
    }

    private func planDateRangeText(_ plan: SocialPlan) -> String {
        let calendar = Calendar(identifier: .gregorian)
        if calendar.isDate(plan.startDate, inSameDayAs: plan.endDate) {
            return socialPlanMonthDayFormatter.string(from: plan.startDate)
        }

        let startText = socialPlanMonthDayFormatter.string(from: plan.startDate)
        let endText = socialPlanMonthDayFormatter.string(from: plan.endDate)
        return "\(startText) - \(endText)"
    }

    @ViewBuilder
    private func tribeChatImage(for chat: TribeChatPreview) -> some View {
        if let photoURL = chat.photoURL {
            AsyncImage(url: photoURL) { phase in
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
        } else {
            Colors.card
        }
    }

    @MainActor
    private func loadJoinedTribeChats() async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id,
              !isLoadingTribeChats else { return }

        isLoadingTribeChats = true
        defer { isLoadingTribeChats = false }

        do {
            let joinRows: [TribeJoinRow] = try await supabase
                .from("tribes_join")
                .select("tribe_id")
                .eq("id", value: userID.uuidString)
                .execute()
                .value

            let tribeIDs = joinRows.map { $0.tribeID }
            if tribeIDs.isEmpty {
                joinedTribeChats = []
                activePlans = []
                return
            }

            let tribeIDStrings = tribeIDs.map { $0.uuidString }
            let tribes: [TribeChatListRow] = try await supabase
                .from("tribes")
                .select("id, name, destination, photo_url")
                .in("id", values: tribeIDStrings)
                .execute()
                .value

            let messageRows: [TribeChatMessageRow] = try await supabase
                .from("tribe_messages")
                .select("tribe_id, text, created_at")
                .in("tribe_id", values: tribeIDStrings)
                .order("created_at", ascending: false)
                .execute()
                .value

            var latestMessageByTribe: [UUID: TribeChatMessageRow] = [:]
            for message in messageRows {
                if latestMessageByTribe[message.tribeID] == nil {
                    latestMessageByTribe[message.tribeID] = message
                }
            }

            let memberRows: [TribeJoinRow] = try await supabase
                .from("tribes_join")
                .select("tribe_id")
                .in("tribe_id", values: tribeIDStrings)
                .execute()
                .value

            var memberCounts: [UUID: Int] = [:]
            for row in memberRows {
                memberCounts[row.tribeID, default: 0] += 1
            }

            let chats = tribes.map { tribe in
                let message = latestMessageByTribe[tribe.id]
                return TribeChatPreview(
                    id: tribe.id,
                    name: tribe.name,
                    destination: tribe.destination,
                    photoURL: tribe.photoURL,
                    lastMessage: message?.text ?? "",
                    lastMessageTime: message.map { socialChatTimeFormatter.string(from: $0.createdAt) } ?? "",
                    memberCount: memberCounts[tribe.id] ?? 0
                )
            }
            joinedTribeChats = chats
            let tribeNamesByID = Dictionary(uniqueKeysWithValues: tribes.map { ($0.id, $0.name) })
            await loadActivePlans(for: tribeIDs, tribeNamesByID: tribeNamesByID, userID: userID)
        } catch {
            return
        }
    }

    @MainActor
    private func loadActivePlans(
        for tribeIDs: [UUID],
        tribeNamesByID: [UUID: String],
        userID: UUID
    ) async {
        guard let supabase else { return }

        let tribeIDStrings = tribeIDs.map { $0.uuidString }
        if tribeIDStrings.isEmpty {
            activePlans = []
            return
        }

        do {
            let rows: [SocialPlanRow] = try await supabase
                .from("plans")
                .select("id, tribe_id, title, start_date, end_date, image_path")
                .in("tribe_id", values: tribeIDStrings)
                .order("start_date", ascending: true)
                .execute()
                .value

            let calendar = Calendar(identifier: .gregorian)
            let today = calendar.startOfDay(for: Date())

            let newPlans = rows.compactMap { row -> SocialPlan? in
                let startDay = calendar.startOfDay(for: row.startDate)
                let endDay = calendar.startOfDay(for: row.endDate)
                guard startDay <= today && endDay >= today else { return nil }

                let imageURL: URL?
                if let imagePath = row.imagePath, !imagePath.isEmpty {
                    imageURL = try? supabase.storage
                        .from("plan-photos")
                        .getPublicURL(path: imagePath)
                } else {
                    imageURL = nil
                }

                return SocialPlan(
                    id: row.id,
                    title: row.title,
                    startDate: row.startDate,
                    endDate: row.endDate,
                    imageURL: imageURL,
                    tribeName: tribeNamesByID[row.tribeID] ?? ""
                )
            }

            activePlans = newPlans
        } catch {
            return
        }
    }
    
    @MainActor
    private func loadFriends() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        do {
            let userRows: [FriendRow] = try await supabase
                .from("friends")
                .select("user_id, friend_id")
                .eq("user_id", value: currentUserID.uuidString)
                .execute()
                .value

            let friendRows: [FriendRow] = try await supabase
                .from("friends")
                .select("user_id, friend_id")
                .eq("friend_id", value: currentUserID.uuidString)
                .execute()
                .value

            let friendIDs = Set(userRows.map { $0.friendID } + friendRows.map { $0.userID })
            if friendIDs.isEmpty {
                friends = []
                return
            }

            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .in("id", values: friendIDs.map { $0.uuidString })
                .execute()
                .value

            friends = profiles
        } catch {
            return
        }
    }

    @MainActor
    private func loadFriendChats() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        let friendIDs = friends.map { $0.id }
        if friendIDs.isEmpty {
            friendChats = []
            return
        }

        let friendIDStrings = friendIDs.map { $0.uuidString }

        do {
            let sentRows: [FriendChatMessageRow] = try await supabase
                .from("friend_messages")
                .select("user_id, friend_id, text, created_at")
                .eq("user_id", value: currentUserID.uuidString)
                .in("friend_id", values: friendIDStrings)
                .execute()
                .value

            let receivedRows: [FriendChatMessageRow] = try await supabase
                .from("friend_messages")
                .select("user_id, friend_id, text, created_at")
                .in("user_id", values: friendIDStrings)
                .eq("friend_id", value: currentUserID.uuidString)
                .execute()
                .value

            var latestMessageByFriend: [UUID: FriendChatMessageRow] = [:]
            for row in sentRows + receivedRows {
                let friendID = row.userID == currentUserID ? row.friendID : row.userID
                if let existing = latestMessageByFriend[friendID] {
                    if row.createdAt > existing.createdAt {
                        latestMessageByFriend[friendID] = row
                    }
                } else {
                    latestMessageByFriend[friendID] = row
                }
            }

            let chats = friends.map { friend in
                let message = latestMessageByFriend[friend.id]
                return FriendChatPreview(
                    id: friend.id,
                    friend: friend,
                    lastMessage: message?.text ?? "",
                    lastMessageTime: message.map { socialChatTimeFormatter.string(from: $0.createdAt) } ?? ""
                )
            }

            friendChats = chats
        } catch {
            return
        }
    }
    
    @MainActor
    private func loadNotificationCount() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        do {
            let incomingRows: [FriendRequestCountRow] = try await supabase
                .from("friend_requests")
                .select("requester_id")
                .eq("receiver_id", value: currentUserID.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value

            let statusRows: [FriendRequestCountRow] = try await supabase
                .from("friend_requests")
                .select("requester_id")
                .eq("requester_id", value: currentUserID.uuidString)
                .in("status", values: ["accepted", "declined"])
                .execute()
                .value

            notificationCount = incomingRows.count + statusRows.count
        } catch {
            return
        }
    }

    private func friendCard(_ friend: UserProfile) -> some View {
        HStack(spacing: 12) {
            friendAvatar(for: friend)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Colors.card, lineWidth: 3)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(friend.fullName)
                        .font(.travelDetail)
                        .foregroundStyle(Colors.primaryText)
                }

                if friend.originFlag != nil || friend.originName != nil {
                    HStack(spacing: 8) {
                        if let flag = friend.originFlag {
                            Text(flag)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)
                        }

                        if let name = friend.originName {
                            Text(name)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func friendAvatar(for friend: UserProfile) -> some View {
        if let avatarURL = friend.avatarURL(using: supabase) {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    Colors.secondaryText.opacity(0.3)
                default:
                    Colors.secondaryText.opacity(0.3)
                }
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }

    private func friendOriginDisplay(for friend: UserProfile) -> String? {
        guard let flag = friend.originFlag, let name = friend.originName else {
            return nil
        }
        return "\(flag) \(name)"
    }
    
}

private struct TribeJoinRow: Decodable {
    let tribeID: UUID

    enum CodingKeys: String, CodingKey {
        case tribeID = "tribe_id"
    }
}

private struct TribeChatListRow: Decodable {
    let id: UUID
    let name: String
    let destination: String
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case destination
        case photoURL = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""

        if let photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURL) {
            photoURL = URL(string: photoURLString)
        } else {
            photoURL = nil
        }
    }
}

private struct TribeChatMessageRow: Decodable {
    let tribeID: UUID
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case tribeID = "tribe_id"
        case text
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tribeID = try container.decode(UUID.self, forKey: .tribeID)
        text = try container.decode(String.self, forKey: .text)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = socialChatTimestampFormatterWithFractional.date(from: createdAtString)
            ?? socialChatTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = createdAtDate
    }
}

private struct FriendRow: Decodable {
    let userID: UUID
    let friendID: UUID

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case friendID = "friend_id"
    }
}

private struct FriendRequestCountRow: Decodable {
    let requesterID: UUID

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
    }
}

private struct FriendChatMessageRow: Decodable {
    let userID: UUID
    let friendID: UUID
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case friendID = "friend_id"
        case text
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(UUID.self, forKey: .userID)
        friendID = try container.decode(UUID.self, forKey: .friendID)
        text = try container.decode(String.self, forKey: .text)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = socialChatTimestampFormatterWithFractional.date(from: createdAtString)
            ?? socialChatTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = createdAtDate
    }
}

private struct SocialPlanRow: Decodable {
    let id: UUID
    let tribeID: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let imagePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tribeID = "tribe_id"
        case title
        case startDate = "start_date"
        case endDate = "end_date"
        case imagePath = "image_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tribeID = try container.decode(UUID.self, forKey: .tribeID)
        title = try container.decode(String.self, forKey: .title)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)

        let startDateString = try container.decode(String.self, forKey: .startDate)
        let endDateString = try container.decode(String.self, forKey: .endDate)
        guard let start = socialPlanDateFormatter.date(from: startDateString),
              let end = socialPlanDateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.startDate], debugDescription: "Invalid plan date format")
            )
        }
        startDate = start
        endDate = end
    }
}

private struct SocialPlan: Identifiable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let imageURL: URL?
    let tribeName: String
}

private struct TribeChatPreview: Identifiable {
    let id: UUID
    let name: String
    let destination: String
    let photoURL: URL?
    let lastMessage: String
    let lastMessageTime: String
    let memberCount: Int
}

private struct FriendChatPreview: Identifiable {
    let id: UUID
    let friend: UserProfile
    let lastMessage: String
    let lastMessageTime: String
}

#Preview {
    MessagesView()
}
