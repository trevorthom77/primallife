import SwiftUI

struct TribesSocialView: View {
    let imageURL: URL?
    let title: String
    let location: String
    let flag: String
    let date: String
    let gender: String?
    let aboutText: String?
    let interests: [String]
    let placeName: String?
    let createdBy: String?
    let onBack: (() -> Void)?
    @State private var placeImageURL: URL?
    @Environment(\.dismiss) private var dismiss
    private let tribeMessages: [ChatMessage] = [
        ChatMessage(text: "Welcome to the Costa Rica crew.", time: "6:10 PM", isUser: false),
        ChatMessage(text: "Landing on the 5th, can't wait.", time: "6:12 PM", isUser: true),
        ChatMessage(text: "We're meeting at Playa Hermosa night one.", time: "6:14 PM", isUser: false),
        ChatMessage(text: "Count me in for the bonfire.", time: "6:15 PM", isUser: true)
    ]

    init(
        imageURL: URL?,
        title: String,
        location: String,
        flag: String,
        date: String,
        gender: String? = nil,
        aboutText: String? = nil,
        interests: [String] = [],
        placeName: String? = nil,
        createdBy: String? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.imageURL = imageURL
        self.title = title
        self.location = location
        self.flag = flag
        self.date = date
        self.gender = gender
        self.aboutText = aboutText
        self.interests = interests
        self.placeName = placeName
        self.createdBy = createdBy
        self.onBack = onBack
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
                    }

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Colors.card)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            } placeholder: {
                                Colors.card
                            }
                            .allowsHitTesting(false)
                        }
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

                        Text(resolvedGender)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(genderAccentColor)
                            .clipShape(Capsule())
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
                    } else if title == "Party Tonight Costa Rica" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)

                            HStack(spacing: 10) {
                                Text("🦈 Sharks")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.tertiaryText)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Colors.accent)
                                    .clipShape(Capsule())

                                Text("🐟 Jeremy Wade")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.tertiaryText)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Colors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

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

                        PlaceCard(imageURL: placeImageURL, name: resolvedPlaceName)
                            .task {
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

private extension TribesSocialView {
    var resolvedAbout: String {
        let trimmed = aboutText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }

        return "Late-night bonfires, sunrise surf, and group dinners along the Nicoya coast. Plans stay loose so everyone can drop in when they land."
    }

    var resolvedGender: String {
        let trimmed = gender?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Everyone" : trimmed
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
        let trimmedPlace = placeName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPlace.isEmpty {
            return trimmedPlace
        }

        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLocation.isEmpty ? "Santa Teresa" : trimmedLocation
    }

    var resolvedCreator: String {
        if let creator = createdBy?.trimmingCharacters(in: .whitespacesAndNewlines), !creator.isEmpty {
            return creator
        }

        if title == "Party Tonight Costa Rica" {
            return "Camila, San José"
        }

        return "You"
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
