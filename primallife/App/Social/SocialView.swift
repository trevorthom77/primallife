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

private enum TribeChatListCache {
    static var latestChats: [TribeChatPreview] = []
    static var chatsByUser: [UUID: [TribeChatPreview]] = [:]

    static func cachedChats(for userID: UUID?) -> [TribeChatPreview] {
        guard let userID else { return latestChats }
        return chatsByUser[userID] ?? latestChats
    }

    static func update(_ chats: [TribeChatPreview], for userID: UUID) {
        chatsByUser[userID] = chats
        latestChats = chats
    }
}

private enum SocialPlanListCache {
    static var latestPlans: [SocialPlan] = []
    static var plansByUser: [UUID: [SocialPlan]] = [:]

    static func cachedPlans(for userID: UUID?) -> [SocialPlan] {
        guard let userID else { return latestPlans }
        return plansByUser[userID] ?? latestPlans
    }

    static func update(_ plans: [SocialPlan], for userID: UUID) {
        plansByUser[userID] = plans
        latestPlans = plans
    }
}

private enum FriendListCache {
    static var latestFriends: [UserProfile] = []
    static var friendsByUser: [UUID: [UserProfile]] = [:]

    static func cachedFriends(for userID: UUID?) -> [UserProfile] {
        guard let userID else { return latestFriends }
        return friendsByUser[userID] ?? latestFriends
    }

    static func update(_ friends: [UserProfile], for userID: UUID) {
        friendsByUser[userID] = friends
        latestFriends = friends
    }
}

private enum SocialPlanImageCache {
    static var images: [URL: Image] = [:]
}

private enum TribeChatImageCache {
    static var images: [URL: Image] = [:]
}

private enum FriendAvatarImageCache {
    static var images: [URL: Image] = [:]
}

struct MessagesView: View {
    @State private var isShowingBell = false
    @State private var joinedTribeChats: [TribeChatPreview] = TribeChatListCache.cachedChats(for: nil)
    @State private var activePlans: [SocialPlan] = SocialPlanListCache.cachedPlans(for: nil)
    @State private var planImageCache: [URL: Image] = SocialPlanImageCache.images
    @State private var tribeChatImageCache: [URL: Image] = TribeChatImageCache.images
    @State private var friendImageCache: [URL: Image] = FriendAvatarImageCache.images
    @State private var isLoadingTribeChats = false
    @State private var friends: [UserProfile] = FriendListCache.cachedFriends(for: nil)
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

                                    Spacer()

                                    Button { } label: {
                                        SeeAllButton()
                                    }
                                }

                                if !joinedTribeChats.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(Array(joinedTribeChats.prefix(3))) { chat in
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
                                        ForEach(Array(friends.prefix(3))) { friend in
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
    
    private func chatRow(_ chat: ChatPreview) -> some View {
        HStack(spacing: 12) {
            Image(chat.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(chat.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(chat.message)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(chat.time)
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.custom(Fonts.semibold, size: 12))
                        .foregroundStyle(Colors.tertiaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Colors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        if let cachedImage = cachedPlanImage(for: url) {
            cachedImage
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            if planImageCache[url] == nil {
                                cachePlanImage(image, for: url)
                            }
                        }
                case .empty:
                    Colors.card
                default:
                    Colors.card
                }
            }
        }
    }

    private func cachedPlanImage(for url: URL) -> Image? {
        planImageCache[url]
    }

    private func cachePlanImage(_ image: Image, for url: URL) {
        planImageCache[url] = image
        SocialPlanImageCache.images[url] = image
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
            if let cachedImage = cachedTribeChatImage(for: photoURL) {
                cachedImage
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                if tribeChatImageCache[photoURL] == nil {
                                    cacheTribeChatImage(image, for: photoURL)
                                }
                            }
                    case .empty:
                        Colors.card
                    default:
                        Colors.card
                    }
                }
            }
        } else {
            Colors.card
        }
    }

    private func cachedTribeChatImage(for url: URL) -> Image? {
        tribeChatImageCache[url]
    }

    private func cacheTribeChatImage(_ image: Image, for url: URL) {
        tribeChatImageCache[url] = image
        TribeChatImageCache.images[url] = image
    }

    @MainActor
    private func loadJoinedTribeChats() async {
        guard let supabase,
              let userID = supabase.auth.currentUser?.id,
              !isLoadingTribeChats else { return }

        let cachedChats = TribeChatListCache.cachedChats(for: userID)
        if joinedTribeChats.isEmpty, !cachedChats.isEmpty {
            joinedTribeChats = cachedChats
        }

        let cachedPlans = SocialPlanListCache.cachedPlans(for: userID)
        if activePlans.isEmpty, !cachedPlans.isEmpty {
            activePlans = cachedPlans
        }

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
                TribeChatListCache.update([], for: userID)
                activePlans = []
                SocialPlanListCache.update([], for: userID)
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
            TribeChatListCache.update(chats, for: userID)
            let tribeNamesByID = Dictionary(uniqueKeysWithValues: tribes.map { ($0.id, $0.name) })
            await loadActivePlans(for: tribeIDs, tribeNamesByID: tribeNamesByID, userID: userID)
        } catch {
            if joinedTribeChats.isEmpty {
                joinedTribeChats = TribeChatListCache.cachedChats(for: userID)
            }
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
            SocialPlanListCache.update([], for: userID)
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
            SocialPlanListCache.update(newPlans, for: userID)
        } catch {
            if activePlans.isEmpty {
                activePlans = SocialPlanListCache.cachedPlans(for: userID)
            }
        }
    }
    
    @MainActor
    private func loadFriends() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        let cachedFriends = FriendListCache.cachedFriends(for: currentUserID)
        if friends.isEmpty, !cachedFriends.isEmpty {
            friends = cachedFriends
        }

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
                FriendListCache.update([], for: currentUserID)
                return
            }

            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .in("id", values: friendIDs.map { $0.uuidString })
                .execute()
                .value

            friends = profiles
            FriendListCache.update(profiles, for: currentUserID)
        } catch {
            if friends.isEmpty {
                friends = FriendListCache.cachedFriends(for: currentUserID)
            }
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
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.fullName)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                if let origin = friendOriginDisplay(for: friend) {
                    Text(origin)
                        .font(.custom(Fonts.regular, size: 14))
                        .foregroundStyle(Colors.secondaryText)
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
            if let cachedImage = cachedFriendImage(for: avatarURL) {
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
                                if friendImageCache[avatarURL] == nil {
                                    cacheFriendImage(image, for: avatarURL)
                                }
                            }
                    case .empty:
                        Colors.secondaryText.opacity(0.3)
                    default:
                        Colors.secondaryText.opacity(0.3)
                    }
                }
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }

    private func cachedFriendImage(for url: URL) -> Image? {
        friendImageCache[url]
    }

    private func cacheFriendImage(_ image: Image, for url: URL) {
        friendImageCache[url] = image
        FriendAvatarImageCache.images[url] = image
    }

    private func friendOriginDisplay(for friend: UserProfile) -> String? {
        guard let flag = friend.originFlag, let name = friend.originName else {
            return nil
        }
        return "\(flag) \(name)"
    }
    
}

struct ChatDetailView: View {
    let chat: ChatPreview
    @State private var draft = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header

                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(chat.messages) { message in
                                messageBubble(message)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height, alignment: .bottom)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            typeBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Colors.background)
        }
        .onTapGesture {
            isInputFocused = false
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            BackButton {
                dismiss()
            }

            Image(chat.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(chat.name)
                    .font(.custom(Fonts.semibold, size: 18))
                    .foregroundStyle(Colors.primaryText)
                    .lineLimit(1)

                HStack(spacing: 8) {
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
                    }

                    Text("\(chat.memberCount) members")
                        .font(.custom(Fonts.regular, size: 14))
                        .foregroundStyle(Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(height: 48, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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
            
            Button(action: {}) {
                Text("Send")
                    .font(.custom(Fonts.semibold, size: 16))
                    .foregroundStyle(Colors.tertiaryText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func messageBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .font(.custom(Fonts.regular, size: 16))
                .foregroundStyle(message.isUser ? Colors.tertiaryText : Colors.primaryText)
                .padding(12)
                .background(message.isUser ? Colors.accent : Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(message.time)
                .font(.custom(Fonts.regular, size: 12))
                .foregroundStyle(Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

struct ChatPreview: Identifiable {
    let id = UUID()
    let name: String
    let unreadCount: Int
    let messages: [ChatMessage]
    let message: String
    let time: String
    let imageName: String
    let memberCount: Int
    
    init(name: String, unreadCount: Int, messages: [ChatMessage], imageName: String, memberCount: Int) {
        self.name = name
        self.unreadCount = unreadCount
        self.messages = messages
        let last = messages.last
        self.message = last?.text ?? ""
        self.time = last?.time ?? ""
        self.imageName = imageName
        self.memberCount = memberCount
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let time: String
    let isUser: Bool
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

#Preview {
    MessagesView()
}
