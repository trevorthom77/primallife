//
//  FriendsChatView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI

struct FriendsChatView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    BackButton {
                        dismiss()
                    }

                    Text("Friend Chat")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)

                    Spacer()
                }

                Text("No messages yet.")
                    .font(.custom(Fonts.regular, size: 16))
                    .foregroundStyle(Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack(spacing: 12) {
                    Text("Message...")
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Colors.contentview)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Send")
                        .font(.custom(Fonts.semibold, size: 16))
                        .foregroundStyle(Colors.tertiaryText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Colors.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
    }
}
