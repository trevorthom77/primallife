//
//  FiltersView.swift
//  primallife
//
//  Created by Trevor Thompson on 2/12/24.
//

import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minAge: Int?
    @Binding var maxAge: Int?
    @Binding var selectedGender: String
    @Binding var selectedCountryID: String?
    @Binding var selectedTravelDescription: String?
    @Binding var selectedInterests: Set<String>
    @State private var showCountryPicker = false
    @State private var showTravelDescriptionPicker = false
    @State private var showInterestsPicker = false
    @State private var minAgeText: String
    @State private var maxAgeText: String
    @State private var draftSelectedGender: String
    @State private var draftSelectedCountryID: String?
    @State private var draftSelectedTravelDescription: String?
    @State private var draftSelectedInterests: Set<String>
    @FocusState private var focusedAgeField: AgeField?

    private var hasSelectedCountry: Bool {
        draftSelectedCountryID != nil
    }

    private var hasSelectedInterests: Bool {
        !draftSelectedInterests.isEmpty
    }

    private var selectedCountryLabel: String {
        guard let draftSelectedCountryID,
              let country = CountryDatabase.all.first(where: { $0.id == draftSelectedCountryID }) else {
            return "Add Country"
        }
        return "\(country.flag) \(country.name)"
    }

    private var selectedTravelDescriptionLabel: String {
        draftSelectedTravelDescription ?? "Add Travel Description"
    }

    private var selectedInterestsLabel: String {
        guard !draftSelectedInterests.isEmpty else { return "Add Interests" }
        let labels = InterestOptions.all.filter { draftSelectedInterests.contains($0) }
        if !labels.isEmpty {
            return labels.joined(separator: ", ")
        }
        return draftSelectedInterests.sorted().joined(separator: ", ")
    }

    private var isAgeRangeInvalid: Bool {
        guard let minValue = ageValue(from: minAgeText),
              let maxValue = ageValue(from: maxAgeText) else {
            return false
        }
        return maxValue < minValue
    }

    private enum AgeField {
        case min
        case max
    }

    private let travelDescriptionOptions = [
        "Backpacking",
        "Gap year",
        "Studying abroad",
        "Living abroad",
        "Just love to travel",
        "Digital nomad"
    ]

    init(
        minAge: Binding<Int?>,
        maxAge: Binding<Int?>,
        selectedGender: Binding<String>,
        selectedCountryID: Binding<String?>,
        selectedTravelDescription: Binding<String?>,
        selectedInterests: Binding<Set<String>>
    ) {
        _minAge = minAge
        _maxAge = maxAge
        _selectedGender = selectedGender
        _selectedCountryID = selectedCountryID
        _selectedTravelDescription = selectedTravelDescription
        _selectedInterests = selectedInterests
        let initialMinAgeText = minAge.wrappedValue.map(String.init) ?? ""
        let initialMaxAgeText = maxAge.wrappedValue.map(String.init) ?? ""
        let initialTravelDescription: String? = {
            let trimmed = selectedTravelDescription.wrappedValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == true ? nil : trimmed
        }()
        _minAgeText = State(initialValue: initialMinAgeText)
        _maxAgeText = State(initialValue: initialMaxAgeText)
        _draftSelectedGender = State(initialValue: selectedGender.wrappedValue)
        _draftSelectedCountryID = State(initialValue: selectedCountryID.wrappedValue)
        _draftSelectedTravelDescription = State(initialValue: initialTravelDescription)
        _draftSelectedInterests = State(initialValue: selectedInterests.wrappedValue)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
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

                    Text("Traveler Filters")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Use filters to refine the travelers you see.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Age range")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)

                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Minimum age")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.primaryText)

                                HStack {
                                    TextField(
                                        "",
                                        text: $minAgeText,
                                        prompt: Text("Enter minimum age")
                                            .foregroundStyle(Colors.secondaryText)
                                    )
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                        .keyboardType(.numberPad)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedAgeField, equals: .min)
                                        .onChange(of: minAgeText) { _, newValue in
                                            let digits = digitsOnly(newValue)
                                            if digits != newValue {
                                                minAgeText = digits
                                            }
                                        }

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Colors.card)
                            .cornerRadius(12)
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                focusedAgeField = .min
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Maximum age")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.primaryText)

                                HStack {
                                    TextField(
                                        "",
                                        text: $maxAgeText,
                                        prompt: Text("Enter maximum age")
                                            .foregroundStyle(Colors.secondaryText)
                                    )
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                        .keyboardType(.numberPad)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedAgeField, equals: .max)
                                        .onChange(of: maxAgeText) { _, newValue in
                                            let digits = digitsOnly(newValue)
                                            if digits != newValue {
                                                maxAgeText = digits
                                            }
                                        }

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Colors.card)
                            .cornerRadius(12)
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                focusedAgeField = .max
                            }
                        }

                        if isAgeRangeInvalid {
                            Text("Maximum age must be at least the minimum age.")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Origin")
                            .font(.travelDetail)
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
                                    draftSelectedCountryID = nil
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Travel description")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)

                        if draftSelectedTravelDescription != nil {
                            HStack(spacing: 12) {
                                Button {
                                    showTravelDescriptionPicker = true
                                } label: {
                                    Text(selectedTravelDescriptionLabel)
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Button("Remove") {
                                    draftSelectedTravelDescription = nil
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
                                showTravelDescriptionPicker = true
                            } label: {
                                Text(selectedTravelDescriptionLabel)
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)

                        if hasSelectedInterests {
                            HStack(spacing: 12) {
                                Button {
                                    showInterestsPicker = true
                                } label: {
                                    Text(selectedInterestsLabel)
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Button("Remove") {
                                    draftSelectedInterests.removeAll()
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
                                showInterestsPicker = true
                            } label: {
                                Text(selectedInterestsLabel)
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gender")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)

                        HStack(spacing: 8) {
                            genderButton(title: "Male")
                            genderButton(title: "Female")
                            genderButton(title: "All")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Colors.card)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button {
                    applyFilters()
                    dismiss()
                } label: {
                    Text("Update")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(isAgeRangeInvalid)
                .opacity(isAgeRangeInvalid ? 0.6 : 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .background(
            Colors.background
                .ignoresSafeArea()
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountryID: $draftSelectedCountryID)
        }
        .sheet(isPresented: $showTravelDescriptionPicker) {
            TravelDescriptionPickerView(
                options: travelDescriptionOptions,
                selectedDescription: $draftSelectedTravelDescription
            )
        }
        .sheet(isPresented: $showInterestsPicker) {
            InterestsPickerView(selectedInterests: $draftSelectedInterests)
        }
        .onChange(of: focusedAgeField) { _, field in
            if field != .min {
                let clamped = clampedAgeText(minAgeText)
                if clamped != minAgeText {
                    minAgeText = clamped
                }
            }
            if field != .max {
                let clamped = clampedAgeText(maxAgeText)
                if clamped != maxAgeText {
                    maxAgeText = clamped
                }
            }
        }
    }
    
    private func digitsOnly(_ text: String) -> String {
        text.filter { $0.isNumber }
    }

    private func clampedAgeText(_ text: String) -> String {
        let digits = digitsOnly(text)
        guard !digits.isEmpty else { return "" }
        let value = Int(digits) ?? 0
        return String(max(18, value))
    }

    private func dismissKeyboard() {
        focusedAgeField = nil
    }

    private func ageValue(from text: String) -> Int? {
        let clamped = clampedAgeText(text)
        guard !clamped.isEmpty else { return nil }
        return Int(clamped)
    }

    private func normalizedAgeRange() -> (minAge: Int?, maxAge: Int?) {
        let minValue = ageValue(from: minAgeText)
        let maxValue = ageValue(from: maxAgeText)
        guard let minValue, let maxValue else { return (minValue, maxValue) }
        return (min(minValue, maxValue), max(minValue, maxValue))
    }

    private func applyFilters() {
        minAge = ageValue(from: minAgeText)
        maxAge = ageValue(from: maxAgeText)
        selectedGender = draftSelectedGender
        selectedCountryID = draftSelectedCountryID
        selectedTravelDescription = draftSelectedTravelDescription
        selectedInterests = draftSelectedInterests
    }
    
    private func genderButton(title: String) -> some View {
        Button {
            draftSelectedGender = title
        } label: {
            Text(title)
                .font(.travelBodySemibold)
                .foregroundStyle(draftSelectedGender == title ? Colors.tertiaryText : Colors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(draftSelectedGender == title ? Colors.accent : Color.clear)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func resetFilters() {
        minAge = nil
        maxAge = nil
        selectedGender = "All"
        selectedCountryID = nil
        selectedTravelDescription = nil
        selectedInterests = []
        minAgeText = ""
        maxAgeText = ""
        draftSelectedGender = "All"
        draftSelectedCountryID = nil
        draftSelectedTravelDescription = nil
        draftSelectedInterests = []
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
                .scrollDismissesKeyboard(.immediately)
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

private struct TravelDescriptionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let options: [String]
    @Binding var selectedDescription: String?
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var selectedDescriptionText: String {
        selectedDescription ?? ""
    }

    private var filteredOptions: [String] {
        let query = searchText.trimmingCharacters(in: .whitespaces)

        if query.isEmpty || query == selectedDescriptionText {
            return options
        }
        return options.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Travel description")
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
                    TextField("Search travel description", text: $searchText)
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
                        ForEach(filteredOptions, id: \.self) { option in
                            let isSelected = selectedDescription == option

                            Button {
                                if isSelected {
                                    selectedDescription = nil
                                } else {
                                    selectedDescription = option
                                }
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(.travelBody)
                                        .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                    Spacer()
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
                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
            }
            .padding(.top, 8)
        }
    }
}

private struct InterestsPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedInterests: Set<String>

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Interests")
                        .font(.customTitle)
                        .foregroundStyle(Colors.primaryText)

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(InterestOptions.all, id: \.self) { interest in
                            let isSelected = selectedInterests.contains(interest)

                            Button {
                                toggleInterest(interest)
                            } label: {
                                Text(interest)
                                    .font(.travelBody)
                                    .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Colors.accent : Colors.card)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests = [interest]
        }
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
