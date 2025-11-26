//
//  MessagesView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/18/25.
//

import SwiftUI

struct MessagesView: View {
    @State private var isShowingBell = false
    
    private let chats: [ChatPreview] = [
        ChatPreview(name: "Aurora Tribe", message: "Marina meetup tonight?", time: "7:45 PM", unreadCount: 2),
        ChatPreview(name: "Coastal Crew", message: "Waves look perfect tomorrow.", time: "6:30 PM", unreadCount: 0),
        ChatPreview(name: "Sierra Pack", message: "Sunrise hike confirmed.", time: "5:10 PM", unreadCount: 1)
    ]
    
    private let friends: [Friend] = [
        Friend(name: "Ava", status: "Online"),
        Friend(name: "Maya", status: "In Costa Rica"),
        Friend(name: "Liam", status: "Planning"),
        Friend(name: "Noah", status: "Offline")
    ]

    private let plans: [Plan] = [
        Plan(title: "Beach Run", detail: "Tomorrow • 7:00 AM"),
        Plan(title: "Sunset Climb", detail: "Friday • 5:30 PM"),
        Plan(title: "Cafe Check-in", detail: "Sunday • 10:00 AM")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Chats")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                VStack(spacing: 12) {
                                    ForEach(chats) { chat in
                                        chatRow(chat)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Plans")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                VStack(spacing: 12) {
                                    ForEach(plans) { plan in
                                        planRow(plan)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Friends")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                VStack(spacing: 12) {
                                    ForEach(friends) { friend in
                                        friendRow(friend)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingBell) {
                BellView()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Social")
                .font(.customTitle)
                .foregroundStyle(Colors.primaryText)
            
            Spacer()
            
            Button(action: {
                isShowingBell = true
            }) {
                ZStack {
                    Circle()
                        .fill(Colors.card)
                        .frame(width: 44, height: 44)
                    
                    Image("bell")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Colors.primaryText)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Colors.background)
    }
    
    private func chatRow(_ chat: ChatPreview) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Colors.accent)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(chat.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(chat.message)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(chat.time)
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.custom(Fonts.semibold, size: 12))
                        .foregroundStyle(Colors.tertiaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Colors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func planRow(_ plan: Plan) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.accent)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(plan.detail)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Colors.accent)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(friend.status)
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct ChatPreview: Identifiable {
    let id = UUID()
    let name: String
    let message: String
    let time: String
    let unreadCount: Int
}

private struct Friend: Identifiable {
    let id = UUID()
    let name: String
    let status: String
}

private struct Plan: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

#Preview {
    MessagesView()
}
