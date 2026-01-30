//
//  HomeView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab = "map"
    @State private var hideChrome = false
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            tabContent
        }
        .overlay(alignment: .bottom) {
            if !hideChrome {
                BottomBar(selectedTab: $selectedTab)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            MapBoxView(hideChrome: $hideChrome, minZoomOut: 6.0)
                .opacity(selectedTab == "map" ? 1 : 0)
                .allowsHitTesting(selectedTab == "map")

            GlobeMapView(minZoomOut: 6.0)
                .opacity(selectedTab == "globe" ? 1 : 0)
                .allowsHitTesting(selectedTab == "globe")

            MyTripsView()
                .opacity(selectedTab == "airplane" ? 1 : 0)
                .allowsHitTesting(selectedTab == "airplane")

            MessagesView()
                .opacity(selectedTab == "message" ? 1 : 0)
                .allowsHitTesting(selectedTab == "message")
        }
    }
}

#Preview {
    HomeView()
}
