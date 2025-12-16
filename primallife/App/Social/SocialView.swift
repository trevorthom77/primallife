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
        ChatPreview(
            name: "Aurora Tribe",
            unreadCount: 2,
            messages: [
                ChatMessage(text: "Marina meetup tonight?", time: "7:40 PM", isUser: false),
                ChatMessage(text: "I can be there by 8.", time: "7:42 PM", isUser: true),
                ChatMessage(text: "Perfect—bring boards?", time: "7:44 PM", isUser: false),
                ChatMessage(text: "Already packed.", time: "7:45 PM", isUser: true)
            ]
        ),
        ChatPreview(
            name: "Coastal Crew",
            unreadCount: 0,
            messages: [
                ChatMessage(text: "Waves look perfect tomorrow.", time: "6:18 PM", isUser: false),
                ChatMessage(text: "Let’s roll at sunrise.", time: "6:21 PM", isUser: true),
                ChatMessage(text: "Meet at the north lot?", time: "6:26 PM", isUser: false),
                ChatMessage(text: "North lot works. I’ll bring extra wax.", time: "6:30 PM", isUser: true)
            ]
        ),
        ChatPreview(
            name: "Sierra Pack",
            unreadCount: 1,
            messages: [
                ChatMessage(text: "Sunrise hike confirmed.", time: "5:02 PM", isUser: false),
                ChatMessage(text: "Layer up—trail will be cold.", time: "5:05 PM", isUser: false),
                ChatMessage(text: "Packing headlamps now.", time: "5:08 PM", isUser: true),
                ChatMessage(text: "See you at the trailhead.", time: "5:10 PM", isUser: true)
            ]
        )
    ]
    
    private let friends: [Friend] = [
        Friend(
            name: "Ava",
            countryFlag: "🇦🇺",
            country: "Australia",
            imageName: "profile1",
            about: "Surf trips, sunrise runs, and finding hidden beaches.",
            tripPlans: [
                TripPlan(title: "Bali Surf", location: "Bali", flag: "🇮🇩", dates: "May 12–18", imageQuery: "Bali beach"),
                TripPlan(title: "Noosa Run", location: "Noosa", flag: "🇦🇺", dates: "Jun 4–6", imageQuery: "Noosa beach")
            ]
        ),
        Friend(
            name: "Maya",
            countryFlag: "🇨🇷",
            country: "Costa Rica",
            imageName: "profile2",
            about: "Living between jungle trails and ocean breaks.",
            tripPlans: [
                TripPlan(title: "Santa Teresa", location: "Santa Teresa", flag: "🇨🇷", dates: "Apr 22–25", imageQuery: "Santa Teresa beach")
            ]
        ),
        Friend(
            name: "Liam",
            countryFlag: "🇮🇪",
            country: "Ireland",
            imageName: "profile3",
            about: "Climbing, cold plunges, and slow travel.",
            tripPlans: [
                TripPlan(title: "Swiss Alps", location: "Swiss Alps", flag: "🇨🇭", dates: "Jul 8–15", imageQuery: "Swiss Alps mountains")
            ]
        ),
        Friend(
            name: "Noah",
            countryFlag: "🇺🇸",
            country: "United States",
            imageName: "profile4",
            about: "Road trips, camp coffee, and desert nights.",
            tripPlans: [
                TripPlan(title: "Zion", location: "Zion", flag: "🇺🇸", dates: "May 1–3", imageQuery: "Zion cliffs"),
                TripPlan(title: "Big Sur", location: "Big Sur", flag: "🇺🇸", dates: "Jun 18–20", imageQuery: "Big Sur coast")
            ]
        )
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
                                        NavigationLink {
                                            ChatDetailView(chat: chat)
                                        } label: {
                                            chatRow(chat)
                                        }
                                        .buttonStyle(.plain)
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
                                        NavigationLink {
                                            OthersProfileView(friend: friend)
                                        } label: {
                                            friendRow(friend)
                                        }
                                        .buttonStyle(.plain)
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
                .overlay(alignment: .topTrailing) {
                    Text("3")
                        .font(.custom(Fonts.semibold, size: 12))
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(width: 20, height: 20)
                        .background(Colors.accent)
                        .clipShape(Circle())
                        .padding(2)
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
                
            Text("\(friend.countryFlag) \(friend.country)")
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

struct ChatDetailView: View {
    let chat: ChatPreview
    @State private var draft = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(chat.messages) { message in
                            messageBubble(message)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .bottom)
                }
                .scrollIndicators(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom) {
            typeBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Colors.background)
        }
        .onTapGesture {
            isInputFocused = false
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var typeBar: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if draft.isEmpty {
                    Text("Message...")
                        .font(.custom(Fonts.regular, size: 16))
                        .foregroundStyle(Colors.secondaryText)
                }

                TextField("", text: $draft, axis: .vertical)
                    .font(.custom(Fonts.regular, size: 16))
                    .foregroundStyle(Colors.primaryText)
                    .tint(Colors.primaryText)
                    .focused($isInputFocused)
            }
            .padding(16)
            .background(Colors.contentview)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button(action: {}) {
                Text("Send")
                    .font(.custom(Fonts.semibold, size: 16))
                    .foregroundStyle(Colors.tertiaryText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func messageBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            Text(message.text)
                .font(.custom(Fonts.regular, size: 16))
                .foregroundStyle(message.isUser ? Colors.tertiaryText : Colors.primaryText)
                .padding(12)
                .background(message.isUser ? Colors.accent : Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(message.time)
                .font(.custom(Fonts.regular, size: 12))
                .foregroundStyle(Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

struct ChatPreview: Identifiable {
    let id = UUID()
    let name: String
    let unreadCount: Int
    let messages: [ChatMessage]
    let message: String
    let time: String
    
    init(name: String, unreadCount: Int, messages: [ChatMessage]) {
        self.name = name
        self.unreadCount = unreadCount
        self.messages = messages
        let last = messages.last
        self.message = last?.text ?? ""
        self.time = last?.time ?? ""
    }
}

struct Friend: Identifiable {
    let id = UUID()
    let name: String
    let countryFlag: String
    let country: String
    let imageName: String
    let about: String
    let tripPlans: [TripPlan]
}

struct TripPlan: Identifiable {
    let id = UUID()
    let title: String
    let location: String
    let flag: String
    let dates: String
    let imageQuery: String
}

private struct Plan: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let time: String
    let isUser: Bool
}

#Preview {
    MessagesView()
}
