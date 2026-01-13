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
            MyTripsView()
                .opacity(selectedTab == "airplane" ? 1 : 0)
                .allowsHitTesting(selectedTab == "airplane")
            
            switch selectedTab {
            case "map":
                MapBoxView(hideChrome: $hideChrome)
            case "airplane":
                 Color.clear
            case "message":
                MessagesView()
            default:
                Color.clear
            }
        }
    }
}

#Preview {
    HomeView()
}
