//
//  EditProfileView.swift
//  primallife
//

import SwiftUI
import Supabase

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @EnvironmentObject private var profileStore: ProfileStore
    @State private var fullName = ""
    @State private var birthday = Date()
    @State private var hasSelectedBirthday = false
    @State private var showBirthdayPicker = false
    @State private var showBirthdayWarning = false
    @State private var originalBirthday: Date?
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentName: String {
        profileStore.profile?.fullName ?? ""
    }

    private var birthdayText: String {
        birthday.formatted(date: .abbreviated, time: .omitted)
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

    private var hasBirthdayChange: Bool {
        guard hasSelectedBirthday else { return false }
        guard let originalBirthday else { return true }
        return !Calendar.current.isDate(originalBirthday, inSameDayAs: birthday)
    }

    private var isSaveEnabled: Bool {
        hasNameChange || hasBirthdayChange
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

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

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            if fullName.isEmpty {
                fullName = currentName
            }

            if originalBirthday == nil {
                let parsed = Self.parseBirthday(profileStore.profile?.birthday)
                originalBirthday = parsed
                if let parsed {
                    birthday = parsed
                    hasSelectedBirthday = true
                }
            }
        }
        .onTapGesture {
            isNameFocused = false
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
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.light)
        }
    }

    @MainActor
    private func saveProfileUpdates() async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        guard hasNameChange || hasBirthdayChange else { return }
        guard !isSaving else { return }

        struct ProfileUpdate: Encodable {
            let fullName: String?
            let birthday: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case birthday
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if let fullName {
                    try container.encode(fullName, forKey: .fullName)
                }
                if let birthday {
                    try container.encode(birthday, forKey: .birthday)
                }
            }
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await supabase
                .from("onboarding")
                .update(
                    ProfileUpdate(
                        fullName: hasNameChange ? trimmedName : nil,
                        birthday: hasBirthdayChange ? birthday.ISO8601Format() : nil
                    )
                )
                .eq("id", value: userID.uuidString)
                .execute()

            await profileStore.loadProfile(for: userID, supabase: supabase)
            dismiss()
        } catch {
            return
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
