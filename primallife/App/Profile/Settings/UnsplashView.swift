//
//  UnsplashView.swift
//  primallife
//
//  Created by Trevor Thompson on 12/3/25.
//

import SwiftUI

struct UnsplashView: View {
    @Environment(\.dismiss) private var dismiss
    private let unsplashURL = URL(string: "https://unsplash.com")!
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BackButton {
                        dismiss()
                    }
                    
                    VStack(alignment: .center, spacing: 12) {
                        Image("unsplash")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                        
                        Text("Powered by Unsplash")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("A special thank you to Unsplash for letting us share their beautiful images and make the app experience even better.")
                            .font(.travelBody)
                            .foregroundStyle(Colors.primaryText)
                        
                        Text("We appreciate the photographers whose work makes every screen feel alive.")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                        
                        Text("Go check them out.")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                        
                        Link(destination: unsplashURL) {
                            HStack {
                                Spacer()
                                Image("unsplashwhite")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 28)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 170, alignment: .topLeading)
                    .background(Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
    }
}
