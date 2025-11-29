//
//  FiltersView.swift
//  primallife
//
//  Created by Trevor Thompson on 2/12/24.
//

import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var minAge: Int = 18
    @State private var maxAge: Int = 100
    @State private var selectedPreset: String = "All Ages"
    @State private var selectedGender: String = "All"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Text("Filters")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    HStack {
                        BackButton {
                            dismiss()
                        }
                        
                        Spacer()
                        
                        Button("Reset") {
                            resetFilters()
                        }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Colors.background)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Age")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            presetButton(title: "18-25", range: 18...25)
                            presetButton(title: "26-35", range: 26...35)
                            presetButton(title: "36-45", range: 36...45)
                        }
                        
                        HStack(spacing: 8) {
                            presetButton(title: "46-60", range: 46...60)
                            presetButton(title: "56+", range: 56...100)
                            presetButton(title: "All Ages", range: nil)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Origin")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    Button(action: { }) {
                        Text("Add Country")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gender")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    HStack(spacing: 8) {
                        genderButton(title: "All")
                        genderButton(title: "Female")
                        genderButton(title: "Male")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Adventure Style")
                        .font(.travelTitle)
                        .foregroundStyle(Colors.primaryText)
                    
                    Button(action: { }) {
                        Text("Add Style")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func presetButton(title: String, range: ClosedRange<Int>?) -> some View {
        Button {
            selectedPreset = title
            if let range {
                minAge = range.lowerBound
                maxAge = range.upperBound
            } else {
                minAge = 18
                maxAge = 100
            }
        } label: {
            Text(title)
                .font(.travelDetail)
                .foregroundStyle(selectedPreset == title ? Colors.tertiaryText : Colors.primaryText)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(selectedPreset == title ? Colors.accent : Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func genderButton(title: String) -> some View {
        Button {
            selectedGender = title
        } label: {
            Text(title)
                .font(.travelDetail)
                .foregroundStyle(selectedGender == title ? Colors.tertiaryText : Colors.primaryText)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(selectedGender == title ? Colors.accent : Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func resetFilters() {
        selectedPreset = "All Ages"
        minAge = 18
        maxAge = 100
        selectedGender = "All"
    }
}

struct TrendingFilters: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopics: Set<String> = []
    
    private let topics: [String] = [
        "Trending Locations",
        "High UV Places",
        "Shark Activity",
        "Beach Escapes",
        "Healthiest Places",
        "Highest Rarity Adventures",
        "People Your Age",
        "More Females",
        "More Boys",
        "Best Food Spots",
        "Budget Friendly",
        "Low Crowds"
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    BackButton {
                        dismiss()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Colors.background)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Topics")
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Text("Select up to 4 topics")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(topics, id: \.self) { topic in
                                    topicButton(for: topic)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func topicButton(for topic: String) -> some View {
        let isSelected = selectedTopics.contains(topic)
        let reachedLimit = selectedTopics.count >= 4 && !isSelected
        
        return Button {
            toggleTopic(topic)
        } label: {
            Text(topic)
                .font(.travelDetail)
                .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(isSelected ? Colors.accent : Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(reachedLimit)
        .opacity(reachedLimit ? 0.6 : 1)
    }
    
    private func toggleTopic(_ topic: String) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else if selectedTopics.count < 4 {
            selectedTopics.insert(topic)
        }
    }
}
