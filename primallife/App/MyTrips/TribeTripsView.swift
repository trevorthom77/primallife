import SwiftUI
import PhotosUI

struct TribeTripsView: View {
    let trip: Trip
    let imageDetails: UnsplashImageDetails?
    @State private var isShowingCreateForm = false
    @Environment(\.dismiss) private var dismiss

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
                    Text("Create a Tribe")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("You’re about to start a tribe for this trip. Your travelers will join here, chat, and stay in sync with the plan.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TravelCard(
                    flag: "🇨🇷",
                    location: trip.destination,
                    dates: "",
                    imageQuery: trip.destination,
                    showsAttribution: true,
                    prefetchedDetails: imageDetails
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("What this does")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("We’ll set up a tribe tied to your trip dates so you and your crew can coordinate in one place.")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
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
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingCreateForm) {
            CreateTribeFormView(trip: trip)
        }
    }

}

private struct CreateTribeFormView: View {
    let trip: Trip
    @State private var groupName: String = ""
    @State private var privacy: TribePrivacy = .public
    @FocusState private var isGroupNameFocused: Bool
    @State private var groupPhoto: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingDetails = false
    @State private var isShowingReview = false
    @State private var aboutText: String = ""
    @State private var selectedInterests: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    private let nameLimit = 30

    init(trip: Trip) {
        self.trip = trip
    }

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
                            .focused($isGroupNameFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                isGroupNameFocused = false
                            }
                            .onChange(of: groupName) { _, newValue in
                                if newValue.count > nameLimit {
                                    groupName = String(newValue.prefix(nameLimit))
                                }
                            }

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
                    Text("Group photo")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            if let image = groupPhoto {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            } else {
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
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    VStack(spacing: 12) {
                        ForEach(TribePrivacy.allCases) { option in
                            Button {
                                privacy = option
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(option.label)
                                        .font(.travelDetail)
                                        .foregroundStyle(selectedTextColor(for: option))

                                    Text(option.description)
                                        .font(.travelBody)
                                        .foregroundStyle(selectedSubtextColor(for: option))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(privacy == option ? Colors.accent : Colors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .onTapGesture {
                isGroupNameFocused = false
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    isShowingDetails = true
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedPhotoItem) { _, newValue in
            loadGroupPhoto(from: newValue)
        }
        .navigationDestination(isPresented: $isShowingDetails) {
            TribeDetailsView(
                aboutText: $aboutText,
                selectedInterests: $selectedInterests,
                onContinue: { isShowingReview = true }
            )
        }
        .navigationDestination(isPresented: $isShowingReview) {
            TribeReviewView(
                groupName: groupName,
                groupPhoto: groupPhoto,
                aboutText: aboutText,
                privacy: privacy,
                selectedInterests: Array(selectedInterests)
            )
        }
    }

    private func selectedTextColor(for option: TribePrivacy) -> Color {
        option == privacy ? Colors.tertiaryText : Colors.primaryText
    }

    private func selectedSubtextColor(for option: TribePrivacy) -> Color {
        option == privacy ? Colors.tertiaryText.opacity(0.9) : Colors.secondaryText
    }

    private func loadGroupPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }

            await MainActor.run {
                groupPhoto = image
            }
        }
    }
}

private enum TribePrivacy: String, CaseIterable, Identifiable {
    case `public` = "Public"
    case `private` = "Private"

    var id: String { rawValue }
    var label: String { rawValue }
    var description: String {
        switch self {
        case .public:
            return "Open to anyone with the link to view and join."
        case .private:
            return "Only invited travelers can see this tribe."
        }
    }
}

private struct TribeDetailsView: View {
    @Binding var aboutText: String
    @Binding var selectedInterests: Set<String>
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAboutFocused: Bool
    private let interestsLimit = 6
    private let interests = [
        "🧭 Adventure",
        "✝️ God",
        "🧳 Solo Traveling",
        "🚗 Road Trips",
        "🚐 Van Travel",
        "🛳️ Cruises",
        "🛥️ Boats",
        "⛵️ Sailing",
        "🚤 Jet Skis",
        "🏝️ Island Hopping",
        "🤿 Scuba Diving",
        "🏄 Surfing",
        "🛶 Kayaking",
        "🎣 Fishing",
        "🦈 Sharks",
        "🌊 Ocean",
        "🏖️ Beaches",
        "🌴 Tropical",
        "🌧️ Rainforests",
        "🍃 Nature",
        "🏞️ National Parks",
        "🧗 Rock Climbing",
        "🥾 Hiking",
        "🚲 Biking",
        "⛺️ Camping",
        "🌲 Off Grid",
        "🎿 Snow and Ski",
        "🏅 Sports",
        "🐶 Animal Lover",
        "🍽️ Food",
        "🛍️ Shopping",
        "🍻 Bar Hopping",
        "🌃 Nightlife",
        "🎨 Art",
        "📸 Photography",
        "🖼️ Museums",
        "🛏️ Hostels",
        "💸 Budget Travel",
        "🛎️ Luxury Travel"
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
                            .focused($isAboutFocused)
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
                            let isSelected = selectedInterests.contains(interest)

                            Button {
                                toggleInterest(interest)
                            } label: {
                                Text(interest)
                                    .font(isSelected ? .custom(Fonts.semibold, size: 18) : .travelBody)
                                    .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Colors.accent : Colors.card)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .onTapGesture {
                isAboutFocused = false
            }
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .background(Colors.background)
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else if selectedInterests.count < interestsLimit {
            selectedInterests.insert(interest)
        }
    }
}

private struct TribeReviewView: View {
    let groupName: String
    let groupPhoto: UIImage?
    let aboutText: String
    let privacy: TribePrivacy
    let selectedInterests: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Review your tribe")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Text("This is what travelers will see.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ZStack {
                        if let image = groupPhoto {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Colors.card
                                .overlay {
                                    Text("No photo added")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(groupName.isEmpty ? "Untitled tribe" : groupName)
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)

                        Text(privacy.label)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Colors.accent)
                            .clipShape(Capsule())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        Text(aboutText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No description added yet." : aboutText)
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        if selectedInterests.isEmpty {
                            Text("No interests selected.")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                                ForEach(selectedInterests, id: \.self) { interest in
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
                    }
                }
                .padding(16)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: { }) {
                    Text("Create Tribe")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .background(Colors.background)
        }
    }
}

#Preview {
    let sampleTripData = """
    {
        "id": "00000000-0000-0000-0000-000000000001",
        "user_id": "00000000-0000-0000-0000-000000000002",
        "destination": "Costa Rica",
        "check_in": "2025-01-12",
        "return_date": "2025-01-20",
        "created_at": "2025-01-01T00:00:00Z"
    }
    """.data(using: .utf8)!

    let sampleTrip = try! JSONDecoder().decode(Trip.self, from: sampleTripData)

    let sampleDetails = UnsplashImageDetails(
        url: URL(string: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e")!,
        photographerName: "Preview Photographer",
        photographerProfileURL: URL(string: "https://unsplash.com")!
    )

    return TribeTripsView(
        trip: sampleTrip,
        imageDetails: sampleDetails
    )
}
