//
//  SettingsView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/25/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                        settingRow("Logout") { }
                        divider
                        settingRow("Delete Account", isDestructive: true) { }
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
    
    private func settingRow(_ title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(isDestructive ? Color.red : Colors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    private var divider: some View {
        Colors.secondaryText
            .opacity(0.15)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
