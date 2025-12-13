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
                        settingRow("Hide Activity Status") { }
                    }
                    
                    settingsSection(title: "Privacy") {
                        settingRow("Block Contacts") { }
                        divider
                        settingRow("Report") { }
                    }
                    
                    settingsSection(title: "Store") {
                        settingRow("Write a Review") { }
                        divider
                        settingRow("Restore Purchases") { }
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

#Preview {
    NavigationStack {
        SettingsView()
    }
}
