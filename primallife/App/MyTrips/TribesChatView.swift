import SwiftUI

struct TribesChatView: View {
    let title: String
    let location: String
    let imageURL: URL?
    let totalTravelers: Int
    let messages: [ChatMessage]
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { message in
                            messageBubble(message)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    typeBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .padding(.bottom, 70)
                        .background(Colors.background)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var typeBar: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $draft, axis: .vertical)
                .font(.custom(Fonts.regular, size: 16))
                .padding(16)
                .background(Colors.card)
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
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
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

            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Colors.card
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(Fonts.semibold, size: 18))
                    .foregroundStyle(Colors.primaryText)
                    .lineLimit(1)

                Spacer()

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
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Colors.background)
    }
}
