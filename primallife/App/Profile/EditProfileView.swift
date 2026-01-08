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
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentName: String {
        profileStore.profile?.fullName ?? ""
    }

    private var isSaveEnabled: Bool {
        let updatedName = trimmedName
        return !updatedName.isEmpty && updatedName != currentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
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
                            await saveFullName()
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
        }
        .onTapGesture {
            isNameFocused = false
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
    }

    @MainActor
    private func saveFullName() async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let updatedName = trimmedName
        guard !updatedName.isEmpty else { return }
        guard !isSaving else { return }

        struct FullNameUpdate: Encodable {
            let full_name: String
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await supabase
                .from("onboarding")
                .update(FullNameUpdate(full_name: updatedName))
                .eq("id", value: userID.uuidString)
                .execute()

            await profileStore.loadProfile(for: userID, supabase: supabase)
            dismiss()
        } catch {
            return
        }
    }
}
