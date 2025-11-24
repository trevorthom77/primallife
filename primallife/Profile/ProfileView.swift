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
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        zoom: 1,
        bearing: 0,
        pitch: 0
    )
    @State private var cardState: CardState = .mid
    
    private enum CardState {
        case peek
        case mid
        case full
    }
    
    var body: some View {
        GeometryReader { proxy in
            let peekHeight = proxy.size.height * 0.2
            let midHeight = proxy.size.height * 0.6
            let fullHeight = proxy.size.height
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
            
            ZStack(alignment: .bottomLeading) {
                Map(viewport: $viewport)
                    .mapStyle(
                        MapStyle(
                            uri: StyleURI(
                                rawValue: "mapbox://styles/trevorthom7/cmi6lppz6001i01sachln4nbu"
                            )!
                        )
                    )
                    .ignoresSafeArea()
                
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 32,
                        topTrailing: 32
                    )
                )
                .fill(Colors.card)
                .frame(height: currentHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                
                Image("profile1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Colors.card, lineWidth: 4)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, currentHeight - (avatarSize / 2) - 30)
            }
        }
    }
}

#Preview {
    ProfileView()
}
