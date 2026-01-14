//
//  FiltersView.swift
//  primallife
//
//  Created by Trevor Thompson on 2/12/24.
//

import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minAge: Int
    @Binding var maxAge: Int
    @Binding var selectedGender: String
    @Binding var selectedCountryID: String?
    @State private var showCountryPicker = false

    private var hasSelectedCountry: Bool {
        selectedCountryID != nil
    }

    private var selectedCountryLabel: String {
        guard let selectedCountryID,
              let country = CountryDatabase.all.first(where: { $0.id == selectedCountryID }) else {
            return "Add Country"
        }
        return "\(country.flag) \(country.name)"
    }
    
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
                    
                    if hasSelectedCountry {
                        HStack(spacing: 12) {
                            Button {
                                showCountryPicker = true
                            } label: {
                                Text(selectedCountryLabel)
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)

                            Button("Remove") {
                                selectedCountryID = nil
                            }
                            .font(.travelDetail)
                            .foregroundStyle(Colors.accent)
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button {
                            showCountryPicker = true
                        } label: {
                            Text(selectedCountryLabel)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.tertiaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
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
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountryID: $selectedCountryID)
        }
    }
    
    private func presetButton(title: String, range: ClosedRange<Int>?) -> some View {
        let isSelected = range.map { minAge == $0.lowerBound && maxAge == $0.upperBound }
            ?? (minAge == 18 && maxAge == 100)

        return Button {
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
                .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(isSelected ? Colors.accent : Colors.card)
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
        minAge = 18
        maxAge = 100
        selectedGender = "All"
        selectedCountryID = nil
    }
}

private struct CountryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountryID: String?
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var selectedCountryText: String {
        guard let selectedCountryID,
              let country = CountryDatabase.all.first(where: { $0.id == selectedCountryID }) else {
            return ""
        }
        return "\(country.flag) \(country.name)"
    }

    private var filteredCountries: [Country] {
        let query = searchText.trimmingCharacters(in: .whitespaces)

        if query.isEmpty || query == selectedCountryText {
            return CountryDatabase.all
        }
        return CountryDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Origin")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField("Search city or country", text: $searchText)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            isSearchFocused = false
                        }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .cornerRadius(12)
                .padding(.horizontal, 24)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCountries) { country in
                            let isSelected = selectedCountryID == country.id

                            Button {
                                if isSelected {
                                    selectedCountryID = nil
                                    searchText = ""
                                } else {
                                    selectedCountryID = country.id
                                    searchText = "\(country.flag) \(country.name)"
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(country.flag)
                                        .font(.travelTitle)
                                    Text(country.name)
                                        .font(.travelBody)
                                        .foregroundColor(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.top, 8)
        }
        .onTapGesture {
            isSearchFocused = false
        }
        .ignoresSafeArea(.keyboard)
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
