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
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case "map":
            MapBoxView(hideChrome: $hideChrome)
        case "globe":
            TrendingView()
        case "airplane":
            MyTripsView()
        case "message":
            MessagesView()
        default:
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
