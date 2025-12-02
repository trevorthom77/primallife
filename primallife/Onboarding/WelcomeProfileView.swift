//
//  WelcomeProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 12/1/25.
//

import SwiftUI

struct WelcomeProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome to your profile")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("This is how others will see you.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                ProfilePreviewCard()
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button { } label: {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.goBackFont)
                        .foregroundColor(Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
    }
}

private struct ProfilePreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image("profile1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 104, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Alex Rider")
                            .font(.customTitle)
                            .foregroundColor(Colors.primaryText)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Colors.accent)
                    }
                    
                    Text("🇨🇦 Vancouver")
                        .font(.travelDetail)
                        .foregroundColor(Colors.secondaryText)
                    
                    Text("Age 26")
                        .font(.travelDetail)
                        .foregroundColor(Colors.secondaryText)
                }
                
                Spacer()
            }
            
            HStack {
                Text("Backpacking")
                    .font(.travelDetail)
                    .foregroundColor(Colors.tertiaryText)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Colors.accent)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(.travelDetail)
                    .foregroundColor(Colors.secondaryText)
                Text("Weekend trips, food finds, and early flights. Keeping it light and easy.")
                    .font(.travelBody)
                    .foregroundColor(Colors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Next stop")
                    .font(.travelDetail)
                    .foregroundColor(Colors.secondaryText)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lisbon")
                            .font(.travelBody)
                            .foregroundColor(Colors.primaryText)
                        Text("May 12–18")
                            .font(.travelDetail)
                            .foregroundColor(Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image("travel3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.card)
        .cornerRadius(16)
    }
}

#Preview {
    WelcomeProfileView()
}
