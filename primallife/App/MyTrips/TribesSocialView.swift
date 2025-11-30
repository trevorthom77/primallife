import SwiftUI

struct TribesSocialView: View {
    let imageURL: URL?
    let title: String
    let location: String
    let flag: String
    let date: String
    @State private var santaTeresaImageURL: URL?
    @Environment(\.dismiss) private var dismiss
    private let tribeMessages: [ChatMessage] = [
        ChatMessage(text: "Welcome to the Costa Rica crew.", time: "6:10 PM", isUser: false),
        ChatMessage(text: "Landing on the 5th, can't wait.", time: "6:12 PM", isUser: true),
        ChatMessage(text: "We're meeting at Playa Hermosa night one.", time: "6:14 PM", isUser: false),
        ChatMessage(text: "Count me in for the bonfire.", time: "6:15 PM", isUser: true)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        BackButton {
                            dismiss()
                        }

                        Spacer()
                    }

                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Colors.card
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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

                        Text(date)
                            .font(.travelDetail)
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

                        Text("Late-night bonfires, sunrise surf, and group dinners along the Nicoya coast. Plans stay loose so everyone can drop in when they land.")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 18)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

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

                        PlaceCard(imageURL: santaTeresaImageURL, name: "Santa Teresa")
                            .task {
                                santaTeresaImageURL = await UnsplashService.fetchImage(for: "Santa Teresa Costa Rica")
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
                            Image("profile2")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(Colors.card, lineWidth: 4)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Camila, San José")
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
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 96)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct PlaceCard: View {
    let imageURL: URL?
    let name: String

    var body: some View {
        ZStack {
            if let imageURL {
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
