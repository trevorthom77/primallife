import SwiftUI

struct UpcomingTripsFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterCheckInDate: Date?
    @Binding var filterReturnDate: Date?
    @Binding var filterMinAge: Int?
    @Binding var filterMaxAge: Int?
    @Binding var filterGender: String?
    @Binding var filterOriginID: String?
    @Binding var filterTribeType: String?
    let showsTribeFilters: Bool
    @State private var checkInDate: Date
    @State private var returnDate: Date
    @State private var hasCheckInDate: Bool
    @State private var hasReturnDate: Bool
    @State private var activeDatePicker: DatePickerType?
    @State private var showOriginPicker = false
    @State private var minAgeText: String = ""
    @State private var maxAgeText: String = ""
    @FocusState private var focusedAgeField: AgeField?
    @State private var selectedGender: GenderOption
    @State private var selectedTribeFilter: TribeFilterOption
    @State private var selectedOriginID: String? = nil
    @State private var selectedTravelDescription: String? = nil
    @State private var showTravelDescriptionPicker = false

    init(
        filterCheckInDate: Binding<Date?>,
        filterReturnDate: Binding<Date?>,
        filterMinAge: Binding<Int?>,
        filterMaxAge: Binding<Int?>,
        filterGender: Binding<String?>,
        filterOriginID: Binding<String?>,
        filterTribeType: Binding<String?>,
        showsTribeFilters: Bool
    ) {
        _filterCheckInDate = filterCheckInDate
        _filterReturnDate = filterReturnDate
        _filterMinAge = filterMinAge
        _filterMaxAge = filterMaxAge
        _filterGender = filterGender
        _filterOriginID = filterOriginID
        _filterTribeType = filterTribeType
        self.showsTribeFilters = showsTribeFilters
        let initialCheckIn = filterCheckInDate.wrappedValue ?? Date()
        let initialReturn = filterReturnDate.wrappedValue ?? Date()
        let initialMinAgeText = filterMinAge.wrappedValue.map(String.init) ?? ""
        let initialMaxAgeText = filterMaxAge.wrappedValue.map(String.init) ?? ""
        let initialGender: GenderOption = {
            let rawGender = filterGender.wrappedValue?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if rawGender.localizedCaseInsensitiveCompare(GenderOption.male.rawValue) == .orderedSame {
                return .male
            }
            if rawGender.localizedCaseInsensitiveCompare(GenderOption.female.rawValue) == .orderedSame {
                return .female
            }
            return .all
        }()
        let initialTribeFilter: TribeFilterOption = {
            let rawFilter = filterTribeType.wrappedValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
            if rawFilter.contains("girl") {
                return .girlsOnly
            }
            if rawFilter.contains("boy") {
                return .boysOnly
            }
            return .everyone
        }()
        _checkInDate = State(initialValue: initialCheckIn)
        _returnDate = State(initialValue: initialReturn)
        _hasCheckInDate = State(initialValue: filterCheckInDate.wrappedValue != nil)
        _hasReturnDate = State(initialValue: filterReturnDate.wrappedValue != nil)
        _minAgeText = State(initialValue: initialMinAgeText)
        _maxAgeText = State(initialValue: initialMaxAgeText)
        _selectedGender = State(initialValue: initialGender)
        _selectedTribeFilter = State(initialValue: initialTribeFilter)
        _selectedOriginID = State(initialValue: filterOriginID.wrappedValue)
    }

    private enum DatePickerType {
        case checkIn
        case returnDate
    }

    private enum AgeField {
        case min
        case max
    }

    private enum GenderOption: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case all = "All"
    }

    private enum TribeFilterOption: String, CaseIterable {
        case girlsOnly = "Girls only"
        case boysOnly = "Boys only"
        case everyone = "Everyone"
    }

    private let travelDescriptionOptions = [
        "Backpacking",
        "Gap year",
        "Studying abroad",
        "Living abroad",
        "Just love to travel",
        "Digital nomad"
    ]

    private var isAgeRangeInvalid: Bool {
        guard let minAge = ageValue(from: minAgeText),
              let maxAge = ageValue(from: maxAgeText) else {
            return false
        }
        return maxAge < minAge
    }

    private var isReturnDateInvalid: Bool {
        !showsTribeFilters && hasCheckInDate && hasReturnDate && returnDate < checkInDate
    }

    private var hasSelectedOrigin: Bool {
        selectedOriginID != nil
    }

    private var selectedOriginLabel: String {
        guard let selectedOriginID,
              let country = CountryDatabase.all.first(where: { $0.id == selectedOriginID }) else {
            return "Add Country"
        }
        return "\(country.flag) \(country.name)"
    }

    private var selectedTravelDescriptionLabel: String {
        selectedTravelDescription ?? "Add Travel Description"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        BackButton {
                            dismissKeyboard()
                            dismiss()
                        }

                        Spacer()

                        Button("Reset") {
                            dismissKeyboard()
                            resetFilters()
                        }
                        .font(.travelDetail)
                        .foregroundStyle(Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trip Filters")
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(
                            showsTribeFilters
                                ? "Use filters to refine the tribes you see."
                                : "Use filters to refine the travelers you see."
                        )
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .contentShape(Rectangle())

                VStack(spacing: 24) {
                    if showsTribeFilters {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tribe type")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(TribeFilterOption.allCases, id: \.self) { option in
                                    Button {
                                        dismissKeyboard()
                                        selectedTribeFilter = option
                                    } label: {
                                        Text(option.rawValue)
                                            .font(.travelBodySemibold)
                                            .foregroundStyle(
                                                selectedTribeFilter == option
                                                    ? Colors.tertiaryText
                                                    : Colors.primaryText
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedTribeFilter == option
                                                    ? (option == .girlsOnly ? Colors.girlsPink : Colors.accent)
                                                    : Color.clear
                                            )
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)

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
                    }

                    if !showsTribeFilters {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dates")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            VStack(spacing: 12) {
                                Button {
                                    dismissKeyboard()
                                    activeDatePicker = .checkIn
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Check-in date")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        HStack {
                                            Text(hasCheckInDate ? formattedDate(checkInDate) : "Select check-in date")
                                                .font(.travelBody)
                                                .foregroundStyle(hasCheckInDate ? Colors.primaryText : Colors.secondaryText)

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Colors.card)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    dismissKeyboard()
                                    activeDatePicker = .returnDate
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Return date")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        HStack {
                                            Text(hasReturnDate ? formattedDate(returnDate) : "Select return date")
                                                .font(.travelBody)
                                                .foregroundStyle(hasReturnDate ? Colors.primaryText : Colors.secondaryText)

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Colors.card)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }

                            if isReturnDateInvalid {
                                Text("Return date must be after check-in date.")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

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

                            if hasSelectedOrigin {
                                HStack(spacing: 12) {
                                    Button {
                                        showOriginPicker = true
                                    } label: {
                                        Text(selectedOriginLabel)
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)

                                    Button("Remove") {
                                        selectedOriginID = nil
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
                                    showOriginPicker = true
                                } label: {
                                    Text(selectedOriginLabel)
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

                            if selectedTravelDescription != nil {
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
                                        selectedTravelDescription = nil
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
                            Text("Gender")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)

                            HStack(spacing: 8) {
                                ForEach(GenderOption.allCases, id: \.self) { option in
                                    Button {
                                        dismissKeyboard()
                                        selectedGender = option
                                    } label: {
                                        Text(option.rawValue)
                                            .font(.travelBodySemibold)
                                            .foregroundStyle(
                                                selectedGender == option
                                                    ? Colors.tertiaryText
                                                    : Colors.primaryText
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedGender == option
                                                    ? Colors.accent
                                                    : Color.clear
                                            )
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
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
                    dismissKeyboard()
                    filterCheckInDate = hasCheckInDate ? checkInDate : nil
                    filterReturnDate = hasReturnDate ? returnDate : nil
                    filterMinAge = ageValue(from: minAgeText)
                    filterMaxAge = ageValue(from: maxAgeText)
                    filterGender = selectedGender == .all ? nil : selectedGender.rawValue
                    filterOriginID = selectedOriginID
                    if showsTribeFilters {
                        filterTribeType = selectedTribeFilter == .everyone ? nil : selectedTribeFilter.rawValue
                    }
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
                .disabled(isAgeRangeInvalid || isReturnDateInvalid)
                .opacity(isAgeRangeInvalid || isReturnDateInvalid ? 0.6 : 1)
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
        .sheet(isPresented: $showOriginPicker) {
            CountryPickerView(selectedCountryID: $selectedOriginID)
        }
        .sheet(isPresented: $showTravelDescriptionPicker) {
            TravelDescriptionPickerView(
                options: travelDescriptionOptions,
                selectedDescription: $selectedTravelDescription
            )
        }
        .sheet(
            isPresented: Binding(
                get: { activeDatePicker != nil },
                set: { isPresented in
                    if !isPresented {
                        activeDatePicker = nil
                    }
                }
            )
        ) {
            if let picker = activeDatePicker {
                datePickerSheet(for: picker)
            }
        }
    }

    @ViewBuilder
    private func datePickerSheet(for type: DatePickerType) -> some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("Done") {
                        confirmDate(for: type)
                    }
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
                }

                DatePicker(
                    "",
                    selection: dateBinding(for: type),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(Colors.accent)
            }
            .padding(20)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.light)
    }

    private func dateBinding(for type: DatePickerType) -> Binding<Date> {
        switch type {
        case .checkIn:
            return $checkInDate
        case .returnDate:
            return $returnDate
        }
    }

    private func confirmDate(for type: DatePickerType) {
        switch type {
        case .checkIn:
            hasCheckInDate = true
        case .returnDate:
            hasReturnDate = true
        }

        activeDatePicker = nil
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func dismissKeyboard() {
        focusedAgeField = nil
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

    private func ageValue(from text: String) -> Int? {
        let clamped = clampedAgeText(text)
        guard !clamped.isEmpty else { return nil }
        return Int(clamped)
    }

    private func normalizedAgeRange() -> (minAge: Int?, maxAge: Int?) {
        let minAge = ageValue(from: minAgeText)
        let maxAge = ageValue(from: maxAgeText)
        guard let minAge, let maxAge else { return (minAge, maxAge) }
        return (min(minAge, maxAge), max(minAge, maxAge))
    }

    private func resetFilters() {
        filterCheckInDate = nil
        filterReturnDate = nil
        filterMinAge = nil
        filterMaxAge = nil
        filterGender = nil
        filterOriginID = nil
        if showsTribeFilters {
            filterTribeType = nil
        }
        hasCheckInDate = false
        hasReturnDate = false
        checkInDate = Date()
        returnDate = Date()
        minAgeText = ""
        maxAgeText = ""
        selectedGender = .all
        selectedTribeFilter = .everyone
        selectedOriginID = nil
        selectedTravelDescription = nil
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
                                    searchText = ""
                                } else {
                                    selectedDescription = option
                                    searchText = option
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
