import SwiftUI

struct MapTribeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingCreateForm = false

    private let exampleTrips: [(title: String, count: Int, imageName: String)] = [
        ("Beach Hike in Maui", 92, "maui"),
        ("Island Hopping in Fiji", 124, "fiji"),
        ("Lagoon Escape in Aruba", 117, "aruba"),
        ("Surf Trip in Costa Rica", 101, "costa rica"),
        ("Sailing the Bahamas", 139, "bahamas"),
        ("Snorkel Week in Belize", 86, "belize")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                Text("Create a Map Tribe")
                    .font(.customTitle)
                    .foregroundStyle(Colors.primaryText)

                Text("Your tribe shows up on the map wherever your plans take place.")
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)

                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(exampleTrips, id: \.title) { example in
                        VStack(alignment: .leading, spacing: 14) {
                            Image(example.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Text(example.title)
                                .font(.tripsfont)
                                .foregroundStyle(Colors.primaryText)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: -8) {
                                Image("profile4")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile5")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile6")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                Image("profile9")
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

                                    Text("\(example.count)+")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingCreateForm = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingCreateForm) {
            MapTribeCreateFormView()
        }
    }
}

private struct MapTribeCreateFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String = ""
    @State private var isShowingDetails = false
    private let nameLimit = 60

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name your tribe")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 8) {
                        TextField("Group name", text: $groupName)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        HStack {
                            Text("Up to \(nameLimit) characters")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                            Spacer()
                            Text("\(groupName.count)/\(nameLimit)")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tribe photo")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Button(action: {}) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Colors.card)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                VStack(spacing: 8) {
                                    Text("Add photo")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)

                                    Text("Tap to upload a cover for this tribe.")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                                .padding(.horizontal, 16)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use free, beautiful photos from Unsplash for your tribe image.")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)

                        Button(action: {}) {
                            HStack {
                                Spacer()
                                Image("unsplashblack")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 28)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingDetails = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingDetails) {
            MapTribeDetailsView()
        }
    }
}

private struct MapTribeDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aboutText: String = ""
    private let interests = InterestOptions.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("About this tribe")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    ZStack(alignment: .topLeading) {
                        if aboutText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Share what travelers should know about this tribe.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $aboutText)
                            .font(.travelBody)
                            .foregroundStyle(Colors.primaryText)
                            .padding(12)
                            .frame(height: 140)
                            .scrollContentBackground(.hidden)
                    }
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Interests")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(interests, id: \.self) { interest in
                            Button(action: {}) {
                                Text(interest)
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.primaryText)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Colors.card)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {}) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
    }
}
