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

private struct TribeChatMessage: Identifiable {
    let id: UUID
    let text: String
    let time: String
    let isUser: Bool
}

struct TribesChatView: View {
    let tribeID: UUID
    let title: String
    let location: String
    let imageURL: URL?
    let totalTravelers: Int
    @State private var headerImage: Image?
    @State private var messages: [TribeChatMessage] = []
    @State private var draft = ""
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
        _headerImage = State(initialValue: initialHeaderImage)
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(messages) { message in
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
            await loadMessages()
        }
        .navigationBarBackButtonHidden(true)
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

    private func messageBubble(_ message: TribeChatMessage) -> some View {
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

                    Text("\(totalTravelers) travelers")
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

            let currentUserID = supabase.auth.currentUser?.id
            messages = rows.map { row in
                TribeChatMessage(
                    id: row.id,
                    text: row.text,
                    time: tribeChatTimeFormatter.string(from: row.createdAt),
                    isUser: row.senderID == currentUserID
                )
            }
        } catch {
        }
    }

    @MainActor
    private func sendMessage() async {
        let trimmedMessage = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty,
              let supabase,
              let userID = supabase.auth.currentUser?.id else { return }

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
        }
    }
}
