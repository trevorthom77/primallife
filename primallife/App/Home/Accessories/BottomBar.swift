//
//  BottomBar.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI
import Supabase

struct BottomBar: View {
    @Binding var selectedTab: String
    @State private var feedbackToggle = false
    @State private var notificationCount = 0
    @Environment(\.supabaseClient) private var supabase
    
    private var notificationBadgeText: String? {
        guard notificationCount > 0 else { return nil }
        return notificationCount > 9 ? "9+" : "\(notificationCount)"
    }
    
    var body: some View {
        Rectangle()
            .fill(Colors.card)
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .overlay(barContent)
            .background(Colors.card)
            .task {
                await loadNotificationCount()
            }
    }
    
    private var barContent: some View {
        HStack {
            barIcon(name: "map")
            
            Spacer()

            barIcon(name: "globe")

            Spacer()

            barIcon(name: "airplane")
            
            Spacer()
            
            barIcon(name: "message")
        }
        .padding(.horizontal, 50)
    }
    
    private func barIcon(name: String, size: CGFloat = 24) -> some View {
        Button {
            selectedTab = name
            feedbackToggle.toggle()
        } label: {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(selectedTab == name ? Colors.accent : Colors.secondaryText)
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    if name == "message", let badgeText = notificationBadgeText {
                        Text(badgeText)
                            .font(.badgeDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(width: 20, height: 20)
                            .background(Colors.accent)
                            .clipShape(Circle())
                    }
                }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackToggle)
        .buttonStyle(.plain)
    }
    
    @MainActor
    private func loadNotificationCount() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else { return }

        do {
            let incomingRows: [FriendRequestCountRow] = try await supabase
                .from("friend_requests")
                .select("requester_id")
                .eq("receiver_id", value: currentUserID.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value

            let statusRows: [FriendRequestCountRow] = try await supabase
                .from("friend_requests")
                .select("requester_id")
                .eq("requester_id", value: currentUserID.uuidString)
                .in("status", values: ["accepted", "declined"])
                .execute()
                .value

            notificationCount = incomingRows.count + statusRows.count
        } catch {
            return
        }
    }
}

#Preview {
    BottomBar(selectedTab: .constant("map"))
        .background(Colors.background)
}

private struct FriendRequestCountRow: Decodable {
    let requesterID: UUID

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
    }
}
