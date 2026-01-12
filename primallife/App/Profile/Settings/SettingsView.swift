//
//  SettingsView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/25/25.
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var isShowingLogoutConfirm = false
    @State private var isShowingDeleteConfirm = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BackButton {
                        dismiss()
                    }
                    
                    NavigationLink {
                        UnsplashView()
                    } label: {
                        HStack(spacing: 12) {
                            Image("unsplashblack")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 32)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    settingsSection(title: "Preferences") {
                        settingRow("Unit of Measurement") { }
                        divider
                        NavigationLink {
                            BlockedUsersView()
                        } label: {
                            HStack {
                                Text("Blocked")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.primaryText)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    settingsSection(title: "Store") {
                        settingRow("Write a Review") { }
                    }
                    
                    settingsSection(title: "Legal") {
                        settingRow("Rules") { }
                        divider
                        settingRow("Terms and Conditions") { }
                        divider
                        settingRow("Privacy Policy") { }
                    }
                    
                    settingsSection(title: "Account") {
                        settingRow("Logout") {
                            isShowingLogoutConfirm = true
                        }
                        divider
                        settingRow("Delete Account", isDestructive: true) {
                            isShowingDeleteConfirm = true
                        }
                    }
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
        .overlay {
            if isShowingLogoutConfirm {
                confirmationOverlay(
                    title: "Logout",
                    message: "You can sign back in anytime.",
                    confirmTitle: "Logout",
                    isDestructive: false,
                    confirmAction: {
                        isShowingLogoutConfirm = false
                        Task {
                            await signOut()
                        }
                    },
                    cancelAction: {
                        isShowingLogoutConfirm = false
                    }
                )
            }
        }
        .overlay {
            if isShowingDeleteConfirm {
                confirmationOverlay(
                    title: "Delete Account",
                    message: "This removes your profile permanently.",
                    confirmTitle: "Delete",
                    isDestructive: true,
                    confirmAction: {
                        isShowingDeleteConfirm = false
                        Task {
                            await deleteAccount()
                        }
                    },
                    cancelAction: {
                        isShowingDeleteConfirm = false
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.travelDetail)
                .foregroundStyle(Colors.secondaryText)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    private func confirmationOverlay(
        title: String,
        message: String,
        confirmTitle: String,
        isDestructive: Bool,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            Colors.primaryText
                .opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    cancelAction()
                }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(message)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Button(action: cancelAction) {
                        Text("Cancel")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Colors.secondaryText.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Button(action: confirmAction) {
                        Text(confirmTitle)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isDestructive ? Color.red : Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
    
    private func settingRow(_ title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(isDestructive ? Color.red : Colors.primaryText)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var divider: some View {
        Colors.secondaryText
            .opacity(0.15)
            .frame(height: 1)
            .padding(.leading, 16)
    }
    
    private func deleteAccount() async {
        guard let supabase else { return }
        
        do {
            let session = try await supabase.auth.session
            guard let url = URL(string: "https://fefucqrztvepcbfjikrq.functions.supabase.co/delete-user") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                print("Delete account failed: invalid response")
                return
            }
            
            try await supabase.auth.signOut()
            await MainActor.run {
                onboardingViewModel.hasCompletedOnboarding = false
            }
        } catch {
            print("Delete account failed: \(error)")
        }
    }
    
    private func signOut() async {
        guard let supabase else { return }
        
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                onboardingViewModel.hasCompletedOnboarding = false
            }
        } catch {
            print("Sign out failed: \(error)")
        }
    }
}

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var blockedUsers: [UserProfile] = []
    @State private var isShowingUnblockConfirm = false
    @State private var selectedBlockedUser: UserProfile?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BackButton {
                        dismiss()
                    }

                    LazyVStack(spacing: 12) {
                        if blockedUsers.isEmpty {
                            Text("No blocked users yet")
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(blockedUsers) { user in
                                blockedUserCard(user)
                            }
                        }
                    }
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
        .task {
            await loadBlockedUsers()
        }
        .overlay {
            if isShowingUnblockConfirm {
                confirmationOverlay(
                    title: "Unblock",
                    message: "Unblock this user?",
                    confirmTitle: "Unblock",
                    isDestructive: false,
                    confirmAction: {
                        let user = selectedBlockedUser
                        isShowingUnblockConfirm = false
                        selectedBlockedUser = nil
                        guard let user else { return }
                        Task {
                            await unblockUser(user)
                        }
                    },
                    cancelAction: {
                        isShowingUnblockConfirm = false
                        selectedBlockedUser = nil
                    }
                )
            }
        }
    }

    private func blockedUserCard(_ user: UserProfile) -> some View {
        HStack(spacing: 12) {
            blockedAvatar(for: user)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Colors.card, lineWidth: 3)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(user.fullName)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
            }

            Spacer()

            Button {
                selectedBlockedUser = user
                isShowingUnblockConfirm = true
            } label: {
                Text("Unblock")
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Colors.contentview)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func confirmationOverlay(
        title: String,
        message: String,
        confirmTitle: String,
        isDestructive: Bool,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            Colors.primaryText
                .opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    cancelAction()
                }

            VStack(spacing: 16) {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                Text(message)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(action: cancelAction) {
                        Text("Keep")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Colors.secondaryText.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: confirmAction) {
                        Text(confirmTitle)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isDestructive ? Color.red : Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func blockedAvatar(for user: UserProfile) -> some View {
        if let avatarURL = user.avatarURL(using: supabase) {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    Colors.secondaryText.opacity(0.3)
                default:
                    Colors.secondaryText.opacity(0.3)
                }
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }

    @MainActor
    private func loadBlockedUsers() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        struct BlockedUserRow: Decodable {
            let blockedID: String

            enum CodingKeys: String, CodingKey {
                case blockedID = "blocked_id"
            }
        }

        do {
            let rows: [BlockedUserRow] = try await supabase
                .from("blocks")
                .select("blocked_id")
                .eq("blocker_id", value: currentUserID.uuidString)
                .execute()
                .value

            let blockedIDs = rows.map { $0.blockedID }
            if blockedIDs.isEmpty {
                blockedUsers = []
                return
            }

            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .in("id", values: blockedIDs)
                .execute()
                .value

            blockedUsers = profiles
        } catch {
            return
        }
    }

    private func unblockUser(_ user: UserProfile) async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        do {
            try await supabase
                .from("blocks")
                .delete()
                .eq("blocker_id", value: currentUserID.uuidString)
                .eq("blocked_id", value: user.id.uuidString)
                .execute()

            await MainActor.run {
                blockedUsers.removeAll { $0.id == user.id }
            }
        } catch {
            return
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
