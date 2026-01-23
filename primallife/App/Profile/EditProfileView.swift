//
//  EditProfileView.swift
//  primallife
//

import SwiftUI
import Supabase
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @EnvironmentObject private var profileStore: ProfileStore
    @State private var fullName = ""
    @State private var bio = ""
    @State private var birthday = Date()
    @State private var hasSelectedBirthday = false
    @State private var showBirthdayPicker = false
    @State private var showBirthdayWarning = false
    @State private var originalBirthday: Date?
    @State private var showOriginPicker = false
    @State private var selectedOriginID: String?
    @State private var originalOriginID: String?
    @State private var showLanguagesPicker = false
    @State private var selectedLanguageIDs: Set<String> = []
    @State private var originalLanguageIDs: Set<String>?
    @State private var showInterestsPicker = false
    @State private var selectedInterests: Set<String> = []
    @State private var originalInterests: Set<String>?
    @State private var originalBio: String?
    @State private var meetingPreference: String?
    @State private var originalMeetingPreference: String?
    @State private var showMeetingPreferencePicker = false
    @State private var travelDescription: String?
    @State private var originalTravelDescription: String?
    @State private var showTravelDescriptionPicker = false
    @State private var isSaving = false
    @State private var avatarImage: UIImage?
    @State private var avatarImageData: Data?
    @State private var isShowingPhotoPicker = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isBioFocused: Bool

    private let meetingPreferenceOptions = ["Only Girls", "Only Boys", "Everyone"]
    private let travelDescriptionOptions = [
        "Backpacking",
        "Gap year",
        "Studying abroad",
        "Living abroad",
        "Just love to travel",
        "Digital nomad"
    ]

    private var trimmedName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBio: String {
        bio.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedMeetingPreference: String? {
        let trimmed = meetingPreference?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == true ? nil : trimmed
    }

    private var normalizedTravelDescription: String? {
        let trimmed = travelDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == true ? nil : trimmed
    }

    private var currentName: String {
        profileStore.profile?.fullName ?? ""
    }

    private var currentBio: String {
        profileStore.profile?.bio ?? ""
    }

    private var currentMeetingPreference: String? {
        profileStore.profile?.meetingPreference
    }

    private var currentTravelDescription: String? {
        profileStore.profile?.travelDescription
    }

    private var currentLanguageIDs: Set<String> {
        Set(profileStore.profile?.languages ?? [])
    }

    private var currentInterests: Set<String> {
        Set(profileStore.profile?.interests ?? [])
    }

    private var birthdayText: String {
        birthday.formatted(date: .abbreviated, time: .omitted)
    }

    private var originDisplay: String? {
        guard
            let selectedOriginID,
            let country = CountryDatabase.all.first(where: { $0.id == selectedOriginID })
        else {
            return nil
        }

        return "\(country.flag) \(country.name)"
    }

    private var maximumBirthday: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private var birthdayBinding: Binding<Date> {
        Binding(
            get: { birthday },
            set: { newValue in
                let clamped = min(newValue, maximumBirthday)
                showBirthdayWarning = newValue > maximumBirthday
                birthday = clamped
                hasSelectedBirthday = true
            }
        )
    }

    private var hasNameChange: Bool {
        let updatedName = trimmedName
        return !updatedName.isEmpty && updatedName != currentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasBioChange: Bool {
        let original = (originalBio ?? currentBio).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedBio != original
    }

    private var hasMeetingPreferenceChange: Bool {
        let original = (originalMeetingPreference ?? currentMeetingPreference)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedOriginal = (original?.isEmpty == true) ? nil : original
        return normalizedMeetingPreference != normalizedOriginal
    }

    private var hasTravelDescriptionChange: Bool {
        let original = (originalTravelDescription ?? currentTravelDescription)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedOriginal = (original?.isEmpty == true) ? nil : original
        return normalizedTravelDescription != normalizedOriginal
    }

    private var hasBirthdayChange: Bool {
        guard hasSelectedBirthday else { return false }
        guard let originalBirthday else { return true }
        return !Calendar.current.isDate(originalBirthday, inSameDayAs: birthday)
    }

    private var hasOriginChange: Bool {
        selectedOriginID != originalOriginID
    }

    private var hasLanguageChange: Bool {
        guard let originalLanguageIDs else { return false }
        return selectedLanguageIDs != originalLanguageIDs
    }

    private var hasInterestsChange: Bool {
        guard let originalInterests else { return false }
        return selectedInterests != originalInterests
    }

    private var hasAvatarChange: Bool {
        avatarImageData != nil
    }

    private var isSaveEnabled: Bool {
        hasNameChange || hasBioChange || hasMeetingPreferenceChange || hasTravelDescriptionChange || hasBirthdayChange || hasOriginChange || hasLanguageChange || hasInterestsChange || hasAvatarChange
    }

    private var selectedLanguages: [Language] {
        LanguageDatabase.all.filter { selectedLanguageIDs.contains($0.id) }
    }

    private var languagesDisplayText: String {
        guard !selectedLanguageIDs.isEmpty else { return "Select languages" }
        let labels = selectedLanguages.map { "\($0.flag) \($0.name)" }
        if !labels.isEmpty {
            return labels.joined(separator: ", ")
        }
        return selectedLanguageIDs.sorted().joined(separator: ", ")
    }

    private var languagesDisplayColor: Color {
        selectedLanguageIDs.isEmpty ? Colors.secondaryText : Colors.primaryText
    }

    private var interestsDisplayText: String {
        guard !selectedInterests.isEmpty else { return "Select interests" }
        let labels = InterestOptions.all.filter { selectedInterests.contains($0) }
        if !labels.isEmpty {
            return labels.joined(separator: ", ")
        }
        return selectedInterests.sorted().joined(separator: ", ")
    }

    private var interestsDisplayColor: Color {
        selectedInterests.isEmpty ? Colors.secondaryText : Colors.primaryText
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        BackButton {
                            dismiss()
                        }
                        .disabled(isSaving)
                        .opacity(isSaving ? 0.6 : 1)

                        Spacer()

                        Button {
                            guard isSaveEnabled else { return }
                            Task {
                                await saveProfileUpdates()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Save")

                                if isSaving {
                                    ProgressView()
                                        .tint(Colors.accent)
                                }
                            }
                        }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                        .disabled(!isSaveEnabled || isSaving)
                        .opacity(isSaveEnabled && !isSaving ? 1 : 0.6)
                    }

                    Text("Edit Profile")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Button {
                        isShowingPhotoPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profile photo")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack(spacing: 16) {
                                avatarPreview
                                    .frame(width: 104, height: 104)
                                    .background(Colors.background)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Change photo")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                    Text("Tap to select a new photo")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.secondaryText)
                                }

                                Spacer()
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.6 : 1)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full name")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)

                        TextField(
                            "",
                            text: $fullName,
                            prompt: Text("Enter your name")
                                .foregroundColor(Colors.secondaryText)
                        )
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            isNameFocused = false
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Colors.card)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isNameFocused = true
                    }

                    Button {
                        showOriginPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Origin")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(originDisplay ?? "Select your origin")
                                    .font(.travelBody)
                                    .foregroundColor(originDisplay == nil ? Colors.secondaryText : Colors.primaryText)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showLanguagesPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Languages")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(languagesDisplayText)
                                    .font(.travelBody)
                                    .foregroundColor(languagesDisplayColor)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showInterestsPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interests")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(interestsDisplayText)
                                    .font(.travelBody)
                                    .foregroundColor(interestsDisplayColor)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)

                        ZStack(alignment: .topLeading) {
                            if trimmedBio.isEmpty {
                                Text("Share what other travelers should know about you")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.secondaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $bio)
                                .font(.travelBody)
                                .foregroundStyle(Colors.primaryText)
                                .padding(12)
                                .frame(height: 140)
                                .scrollContentBackground(.hidden)
                                .focused($isBioFocused)
                        }
                        .background(Colors.card)
                        .cornerRadius(12)
                    }

                    Button {
                        showMeetingPreferencePicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Who do you want to travel with?")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(normalizedMeetingPreference ?? "Select who you want to travel with")
                                    .font(.travelBody)
                                    .foregroundColor(meetingPreferenceDisplayColor)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showTravelDescriptionPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What describes you best?")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(normalizedTravelDescription ?? "Select what describes you best")
                                    .font(.travelBody)
                                    .foregroundColor(normalizedTravelDescription == nil ? Colors.secondaryText : Colors.primaryText)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showBirthdayPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Birthday")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack {
                                Text(hasSelectedBirthday ? birthdayText : "Select your birthday")
                                    .font(.travelBody)
                                    .foregroundColor(hasSelectedBirthday ? Colors.primaryText : Colors.secondaryText)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 96)
            }
        }
        .onAppear {
            if fullName.isEmpty {
                fullName = currentName
            }

            if originalBio == nil {
                let current = currentBio
                originalBio = current
                if bio.isEmpty {
                    bio = current
                }
            }

            if originalMeetingPreference == nil {
                let current = currentMeetingPreference
                originalMeetingPreference = current
                if meetingPreference == nil {
                    meetingPreference = current
                }
            }

            if originalTravelDescription == nil {
                let current = currentTravelDescription
                originalTravelDescription = current
                if travelDescription == nil {
                    travelDescription = current
                }
            }

            if originalBirthday == nil {
                let parsed = Self.parseBirthday(profileStore.profile?.birthday)
                originalBirthday = parsed
                if let parsed {
                    birthday = parsed
                    hasSelectedBirthday = true
                }
            }

            if originalOriginID == nil {
                let origin = profileStore.profile?.origin?.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedOrigin = (origin?.isEmpty == false) ? origin : nil
                originalOriginID = normalizedOrigin
                if selectedOriginID == nil {
                    selectedOriginID = normalizedOrigin
                }
            }

            if originalLanguageIDs == nil {
                let current = currentLanguageIDs
                originalLanguageIDs = current
                selectedLanguageIDs = current
            }

            if originalInterests == nil {
                let current = currentInterests
                originalInterests = current
                selectedInterests = current
            }
        }
        .onTapGesture {
            isNameFocused = false
            isBioFocused = false
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showBirthdayPicker) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Spacer()

                        Button("Done") {
                            showBirthdayPicker = false
                        }
                        .font(.travelDetail)
                        .foregroundColor(Colors.accent)
                    }

                    DatePicker("", selection: birthdayBinding, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(Colors.accent)

                    if showBirthdayWarning {
                        Text("You must be 18 or older.")
                            .font(.travelDetail)
                            .foregroundColor(Colors.accent)
                    }
                }
                .padding(20)
        }
        .presentationDetents([.height(320)])
        .presentationBackground(Colors.background)
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showOriginPicker) {
            OriginPickerSheet(selectedOriginID: $selectedOriginID)
                .presentationBackground(Colors.background)
        }
        .sheet(isPresented: $showLanguagesPicker) {
            LanguagesPickerSheet(selectedLanguageIDs: $selectedLanguageIDs)
                .presentationBackground(Colors.background)
        }
        .sheet(isPresented: $showInterestsPicker) {
            InterestsPickerSheet(selectedInterests: $selectedInterests)
                .presentationBackground(Colors.background)
        }
        .sheet(isPresented: $showMeetingPreferencePicker) {
            MeetingPreferenceSheet(meetingPreference: $meetingPreference, options: meetingPreferenceOptions)
                .presentationDetents([.height(280)])
                .presentationBackground(Colors.background)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showTravelDescriptionPicker) {
            TravelDescriptionSheet(travelDescription: $travelDescription, options: travelDescriptionOptions)
                .presentationDetents([.height(360)])
                .presentationBackground(Colors.background)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $isShowingPhotoPicker) {
            CroppingImagePicker { image, data in
                avatarImage = image
                avatarImageData = data
            }
            .ignoresSafeArea()
        }
    }

    private var meetingPreferenceDisplayColor: Color {
        guard normalizedMeetingPreference != nil else { return Colors.secondaryText }
        return Colors.primaryText
    }

    @MainActor
    private func saveProfileUpdates() async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        guard hasNameChange || hasBioChange || hasMeetingPreferenceChange || hasTravelDescriptionChange || hasBirthdayChange || hasOriginChange || hasLanguageChange || hasInterestsChange || hasAvatarChange else { return }
        guard !isSaving else { return }

        struct ProfileUpdate: Encodable {
            let fullName: String?
            let birthday: String?
            let origin: String?
            let bio: String?
            let avatarPath: String?
            let meetingPreference: String?
            let travelDescription: String?
            let languages: [String]?
            let interests: [String]?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case birthday
                case origin
                case bio
                case avatarPath = "avatar_url"
                case meetingPreference = "meeting_preference"
                case travelDescription = "travel_description"
                case languages
                case interests
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if let fullName {
                    try container.encode(fullName, forKey: .fullName)
                }
                if let birthday {
                    try container.encode(birthday, forKey: .birthday)
                }
                if let origin {
                    try container.encode(origin, forKey: .origin)
                }
                if let bio {
                    try container.encode(bio, forKey: .bio)
                }
                if let avatarPath {
                    try container.encode(avatarPath, forKey: .avatarPath)
                }
                if let meetingPreference {
                    try container.encode(meetingPreference, forKey: .meetingPreference)
                }
                if let travelDescription {
                    try container.encode(travelDescription, forKey: .travelDescription)
                }
                if let languages {
                    try container.encode(languages, forKey: .languages)
                }
                if let interests {
                    try container.encode(interests, forKey: .interests)
                }
            }
        }

        isSaving = true
        defer { isSaving = false }

        var updatedAvatarPath: String?

        if let avatarImageData {
            let path = "\(userID)/avatar.jpg"

            do {
                try await supabase.storage
                    .from("profile-photos")
                    .upload(path, data: avatarImageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

                updatedAvatarPath = path

                AvatarCacheBuster.recordUpdate(for: userID)

                if let avatarImage,
                   let publicURL = makePublicAvatarURL(for: path, userID: userID) {
                    profileStore.cacheAvatar(Image(uiImage: avatarImage), url: publicURL)
                }
            } catch {
                return
            }
        }

        do {
            try await supabase
                .from("onboarding")
                .update(
                    ProfileUpdate(
                        fullName: hasNameChange ? trimmedName : nil,
                        birthday: hasBirthdayChange ? birthday.ISO8601Format() : nil,
                        origin: hasOriginChange ? selectedOriginID : nil,
                        bio: hasBioChange ? trimmedBio : nil,
                        avatarPath: hasAvatarChange ? updatedAvatarPath : nil,
                        meetingPreference: hasMeetingPreferenceChange ? normalizedMeetingPreference : nil,
                        travelDescription: hasTravelDescriptionChange ? normalizedTravelDescription : nil,
                        languages: hasLanguageChange ? selectedLanguageIDs.sorted() : nil,
                        interests: hasInterestsChange ? selectedInterests.sorted() : nil
                    )
                )
                .eq("id", value: userID.uuidString)
                .execute()

            await profileStore.loadProfile(for: userID, supabase: supabase)
            avatarImageData = nil
            dismiss()
        } catch {
            return
        }
    }

    private func makePublicAvatarURL(for path: String, userID: UUID) -> URL? {
        guard let supabase else { return nil }

        do {
            let url = try supabase.storage
                .from("profile-photos")
                .getPublicURL(path: path)
            return AvatarCacheBuster.cacheBustedURL(url, userID: userID)
        } catch {
            return nil
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        let avatarURL = profileStore.profile?.avatarURL(using: supabase)

        if let avatarImage {
            Image(uiImage: avatarImage)
                .resizable()
                .scaledToFill()
        } else if let avatarURL,
                  let cachedImage = profileStore.cachedAvatarImage,
                  profileStore.cachedAvatarURL == avatarURL {
            cachedImage
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            profileStore.cacheAvatar(image, url: avatarURL)
                        }
                default:
                    Color.clear
                }
            }
        } else {
            Color.clear
        }
    }

    private static let birthdayTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let birthdayTimestampFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let birthdayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func parseBirthday(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if let date = birthdayTimestampFormatterWithFractional.date(from: value) {
            return date
        }
        if let date = birthdayTimestampFormatter.date(from: value) {
            return date
        }
        return birthdayDateFormatter.date(from: value)
    }
}

private struct OriginPickerSheet: View {
    @Binding var selectedOriginID: String?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCountries: [Country] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return CountryDatabase.all
        }
        return CountryDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField(
                        "",
                        text: $searchText,
                        prompt: Text("Search country")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    )
                    .font(.travelBody)
                    .foregroundStyle(Colors.primaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .cornerRadius(12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCountries) { country in
                            let isSelected = selectedOriginID == country.id

                            Button {
                                selectedOriginID = country.id
                            } label: {
                                HStack(spacing: 12) {
                                    Text(country.flag)
                                        .font(.travelTitle)
                                    Text(country.name)
                                        .font(.travelBody)
                                        .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct LanguagesPickerSheet: View {
    @Binding var selectedLanguageIDs: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredLanguages: [Language] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return LanguageDatabase.all
        }
        return LanguageDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField(
                        "",
                        text: $searchText,
                        prompt: Text("Search languages")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    )
                    .font(.travelBody)
                    .foregroundStyle(Colors.primaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .cornerRadius(12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredLanguages) { language in
                            let isSelected = selectedLanguageIDs.contains(language.id)

                            Button {
                                if isSelected {
                                    selectedLanguageIDs.remove(language.id)
                                } else {
                                    selectedLanguageIDs.insert(language.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(language.flag)
                                        .font(.travelTitle)
                                    Text(language.name)
                                        .font(.travelBody)
                                        .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct InterestsPickerSheet: View {
    @Binding var selectedInterests: Set<String>

    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(InterestOptions.all, id: \.self) { interest in
                            let isSelected = selectedInterests.contains(interest)

                            Button {
                                toggleInterest(interest)
                            } label: {
                                Text(interest)
                                    .font(.travelBody)
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
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
}

private struct MeetingPreferenceSheet: View {
    @Binding var meetingPreference: String?
    let options: [String]

    @Environment(\.dismiss) private var dismiss

    private var normalizedSelection: String? {
        let trimmed = meetingPreference?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == true ? nil : trimmed
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }

                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = normalizedSelection == option
                        let selectedColor = option == "Only Girls" ? Colors.girlsPink : Colors.accent

                        Button {
                            meetingPreference = option
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.travelBody)
                                Spacer()
                            }
                            .foregroundColor(isSelected ? Colors.tertiaryText : Colors.primaryText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? selectedColor : Colors.card)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct TravelDescriptionSheet: View {
    @Binding var travelDescription: String?
    let options: [String]

    @Environment(\.dismiss) private var dismiss

    private var normalizedSelection: String? {
        let trimmed = travelDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == true ? nil : trimmed
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            let isSelected = normalizedSelection == option

                            Button {
                                travelDescription = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(.travelBody)
                                    Spacer()
                                }
                                .foregroundColor(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct CroppingImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage, Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CroppingImagePicker

        init(parent: CroppingImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let selectedImage,
                  let data = selectedImage.jpegData(compressionQuality: 0.9) else {
                parent.dismiss()
                return
            }

            parent.onImagePicked(selectedImage, data)
            parent.dismiss()
        }
    }
}
