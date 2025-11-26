//
//  ProfileView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import CoreLocation
import MapboxMaps

struct ProfileView: View {
    let name: String
    let homeCountry: String
    let countryFlag: String
    let totalTribesJoined: Int
    let totalTrips: Int
    let countriesVisited: Int
    let tribes: [ProfileTribe]
    let friends: [ProfileFriend]
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        zoom: 1,
        bearing: 0,
        pitch: 0
    )
    @State private var cardState: CardState = .mid
    @State private var activeAction: ProfileAction?
    @State private var actionIsFull = false
    @State private var countrySearchText = ""
    
    private enum CardState {
        case peek
        case mid
        case full
    }
    
    private enum ProfileAction {
        case addCountry
    }
    
    var body: some View {
        GeometryReader { proxy in
            let peekHeight = proxy.size.height * 0.2
            let midHeight = proxy.size.height * 0.6
            let fullHeight = proxy.size.height
            let backButtonTopPadding = max(0, 58 - proxy.safeAreaInsets.top)
            let currentHeight: CGFloat = {
                switch cardState {
                case .peek:
                    return peekHeight
                case .mid:
                    return midHeight
                case .full:
                    return fullHeight
                }
            }()
            let avatarSize: CGFloat = 120
            let dragGesture = DragGesture()
                .onEnded { value in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if value.translation.height < -30 {
                            switch cardState {
                            case .peek:
                                cardState = .mid
                            case .mid:
                                cardState = .full
                            case .full:
                                cardState = .full
                            }
                        } else if value.translation.height > 30 {
                            switch cardState {
                            case .full:
                                cardState = .mid
                            case .mid:
                                cardState = .peek
                            case .peek:
                                cardState = .peek
                            }
                        }
                    }
                }
            
            ZStack(alignment: .bottom) {
                Map(viewport: $viewport)
                    .ornamentOptions(
                        OrnamentOptions(
                            scaleBar: ScaleBarViewOptions(
                                position: .topLeading,
                                margins: .zero,
                                visibility: .hidden,
                                useMetricUnits: true
                            )
                        )
                    )
                    .mapStyle(
                        MapStyle(
                            uri: StyleURI(
                                rawValue: "mapbox://styles/trevorthom7/cmi6lppz6001i01sachln4nbu"
                            )!
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        Text("8%")
                            .font(.custom(Fonts.semibold, size: 96))
                            .foregroundStyle(Colors.tertiaryText)
                            .padding(.trailing, 24)
                            .padding(.top, 88)
                    }
                    .ignoresSafeArea()
                
                if cardState == .peek {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                activeAction = .addCountry
                                actionIsFull = false
                            }) {
                                Text("Add Country")
                                    .font(.custom(Fonts.semibold, size: 18))
                                    .foregroundStyle(Colors.tertiaryText)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 14)
                                    .background(Colors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.bottom, currentHeight + 32)
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    UnevenRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(
                            topLeading: 32,
                            topTrailing: 32
                        )
                    )
                    .fill(Colors.card)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack(alignment: .center, spacing: 16) {
                                Image("profile1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: avatarSize, height: avatarSize)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 4)
                                    }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(name)
                                            .font(.custom(Fonts.semibold, size: 22))
                                            .foregroundStyle(Colors.primaryText)
                                        
                                        verifiedBadge
                                    }
                                    
                                    Text("\(countryFlag) \(homeCountry)")
                                        .font(.custom(Fonts.regular, size: 16))
                                        .foregroundStyle(Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Edit")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.accent)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                statView(value: totalTribesJoined, label: "Tribes")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                statView(value: totalTrips, label: "Trips")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                statView(value: countriesVisited, label: "Countries")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Tribes")
                                            .font(.custom(Fonts.semibold, size: 18))
                                            .foregroundStyle(Colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Button("See All") { }
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.accent)
                                    }
                                    
                                    ForEach(tribes) { tribe in
                                        tribeRow(tribe)
                                    }
                                }
                                .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Friends")
                                            .font(.custom(Fonts.semibold, size: 18))
                                            .foregroundStyle(Colors.primaryText)
                                        
                                        Spacer()
                                        
                                        Button("See All") { }
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.accent)
                                    }
                                    
                                    ForEach(friends) { friend in
                                        friendRow(friend)
                                    }
                                }
                                .padding(.top, 8)
                        }
                        .padding(24)
                    }
                    .scrollDisabled(cardState != .full)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(
                            topLeading: 32,
                            topTrailing: 32
                        )
                    )
                )
                .frame(height: currentHeight)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .contentShape(Rectangle())
                .simultaneousGesture(dragGesture)
            }
            .overlay(alignment: .topLeading) {
                BackButton {
                    dismiss()
                }
                .padding(.leading)
                .padding(.top, backButtonTopPadding)
            }
            .overlay(alignment: .bottom) {
                if let action = activeAction {
                    ZStack(alignment: .bottom) {
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                            .onTapGesture {
                                activeAction = nil
                            }
                        
                        actionOverlay(action, fullHeight: proxy.size.height)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private var verifiedBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("Verified")
                .font(.custom(Fonts.semibold, size: 12))
        }
        .foregroundStyle(Colors.tertiaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Colors.accent)
        .clipShape(Capsule())
    }
    
    private func tribeRow(_ tribe: ProfileTribe) -> some View {
        HStack(spacing: 12) {
            Image(tribe.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Colors.card, lineWidth: 3)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tribe.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                
                Text(tribe.status)
                    .font(.custom(Fonts.regular, size: 14))
                    .foregroundStyle(Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func friendRow(_ friend: ProfileFriend) -> some View {
        HStack(spacing: 12) {
            Image(friend.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Colors.card, lineWidth: 3)
                }
            
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
        .background(Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func statView(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.custom(Fonts.semibold, size: 20))
                .foregroundStyle(Colors.primaryText)
            
            Text(label)
                .font(.custom(Fonts.regular, size: 14))
                .foregroundStyle(Colors.secondaryText)
        }
    }
    
    private func actionOverlay(_ action: ProfileAction, fullHeight: CGFloat) -> some View {
        let targetHeight = actionIsFull ? fullHeight : 320
        return UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 32,
                topTrailing: 32
            )
        )
        .fill(Colors.background)
        .frame(height: targetHeight)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 16) {
                if action == .addCountry {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Colors.primaryText)
                        
                        ZStack(alignment: .leading) {
                            if countrySearchText.isEmpty {
                                Text("Search")
                                    .font(.travelBody)
                                    .foregroundStyle(Colors.primaryText)
                            }
                            
                            TextField("", text: $countrySearchText)
                                .font(.travelBody)
                                .foregroundStyle(Colors.primaryText)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Colors.secondaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(
                                CountryDatabase.all.filter { country in
                                    countrySearchText.isEmpty ? true : country.name.lowercased().contains(countrySearchText.lowercased())
                                }
                            ) { country in
                                Text("\(country.flag) \(country.name)")
                                    .font(.custom(Fonts.regular, size: 16))
                                    .foregroundStyle(Colors.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                    .background(Colors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .ignoresSafeArea(edges: .bottom)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 60 {
                        if actionIsFull {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                actionIsFull = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                activeAction = nil
                            }
                        }
                    } else if value.translation.height < -60 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            actionIsFull = true
                        }
                    }
                }
        )
    }
}

struct ProfileFriend: Identifiable {
    let id = UUID()
    let imageName: String
    let name: String
    let status: String
}

struct ProfileTribe: Identifiable {
    let id = UUID()
    let imageName: String
    let name: String
    let status: String
}

#Preview {
    ProfileView(
        name: "Mia",
        homeCountry: "Australia",
        countryFlag: "🇦🇺",
        totalTribesJoined: 5,
        totalTrips: 12,
        countriesVisited: 8,
        tribes: [
            ProfileTribe(imageName: "profile4", name: "Pacific Explorers", status: "Active"),
            ProfileTribe(imageName: "profile5", name: "Mountain Crew", status: "Planning")
        ],
        friends: [
            ProfileFriend(imageName: "profile1", name: "Ava", status: "Online"),
            ProfileFriend(imageName: "profile2", name: "Maya", status: "Planning"),
            ProfileFriend(imageName: "profile3", name: "Liam", status: "Offline")
        ]
    )
}
