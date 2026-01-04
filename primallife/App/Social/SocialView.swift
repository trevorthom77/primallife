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

private enum TribeChatImageCache {
    static var images: [URL: Image] = [:]
}

struct MessagesView: View {
    @State private var isShowingBell = false
    @State private var joinedTribeChats: [TribeChatPreview] = TribeChatListCache.cachedChats(for: nil)
    @State private var tribeChatImageCache: [URL: Image] = TribeChatImageCache.images
    @State private var isLoadingTribeChats = false
    @Environment(\.supabaseClient) private var supabase
    
    private let plans: [Plan] = [
        Plan(title: "Beach Run", detail: "Tomorrow • 7:00 AM"),
        Plan(title: "Sunset Climb", detail: "Friday • 5:30 PM"),
        Plan(title: "Cafe Check-in", detail: "Sunday • 10:00 AM")
    ]

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
                                Text("Chats")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)

                                if !joinedTribeChats.isEmpty {
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
                                
                                VStack(spacing: 12) {
                                    ForEach(plans) { plan in
                                        planRow(plan)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Friends")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)

                                friendCard
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
                    Text("3")
                        .font(.custom(Fonts.semibold, size: 12))
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(width: 20, height: 20)
                        .background(Colors.accent)
                        .clipShape(Circle())
                        .padding(2)
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
        } catch {
            if joinedTribeChats.isEmpty {
                joinedTribeChats = TribeChatListCache.cachedChats(for: userID)
            }
        }
    }
    
    private func planRow(_ plan: Plan) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.accent)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(plan.detail)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var friendCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Colors.accent)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Ava")
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                Text("🇦🇺 Australia")
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
            }

            Spacer()
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

private struct Plan: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
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
