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

struct FriendsChatView: View {
    let friendID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var messages: [FriendChatMessage] = []
    @State private var friendAvatarURL: URL?
    @State private var friendAvatarImage: Image?
    @State private var draft = ""

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    BackButton {
                        dismiss()
                    }

                    friendAvatar

                    Text("Friend Chat")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Spacer()
                }

                if messages.isEmpty {
                    Text("No messages yet.")
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(messages) { message in
                                messageBubble(message)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                }

                typeBar
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .task(id: friendID) {
            await loadFriendProfile()
            await loadMessages()
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
            }
            .padding(16)
            .background(Colors.contentview)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: {
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
        }
    }

    private func messageBubble(_ message: FriendChatMessage) -> some View {
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

    @MainActor
    private func loadFriendProfile() async {
        friendAvatarURL = nil
        friendAvatarImage = nil

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
        } catch {
            return
        }
    }

    @MainActor
    private func sendMessage() async {
        let trimmedMessage = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty,
              let supabase,
              let currentUserID = supabase.auth.currentUser?.id else { return }

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
            return
        }
    }
}
