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
                VStack(alignment: .leading, spacing: 12) {
                    BackButton {
                        dismiss()
                    }
                    
                    Text("Settings")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    Button(action: { }) {
                        Text("Unit of Measurement")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Hide Activity Status")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Block Contacts")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Report")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Write a Review")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Restore Purchases")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Rules")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Terms and Conditions")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Privacy Policy")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Logout")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { }) {
                        Text("Delete Account")
                            .font(.travelDetail)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                            .padding(.horizontal, 16)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
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
