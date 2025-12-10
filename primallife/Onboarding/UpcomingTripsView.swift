import SwiftUI

struct UpcomingTripsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showProfilePicture = false
    @State private var showDestinationSheet = false
    @State private var showArrivalPicker = false
    @State private var showDepartingPicker = false
    @State private var searchQuery = ""
    @State private var searchResults: [UpcomingMapboxPlace] = []
    @State private var searchTask: Task<Void, Never>?
    
    private var minimumDate: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var isDepartingDateInvalid: Bool {
        onboardingViewModel.hasSelectedArrival && onboardingViewModel.hasSelectedDeparting && onboardingViewModel.departingDate < onboardingViewModel.arrivalDate
    }
    
    private var arrivalDateText: String {
        onboardingViewModel.arrivalDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var departingDateText: String {
        onboardingViewModel.departingDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var isContinueEnabled: Bool {
        !onboardingViewModel.upcomingDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && onboardingViewModel.hasSelectedArrival && onboardingViewModel.hasSelectedDeparting && !isDepartingDateInvalid
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Upcoming trips?")
                        Text("✈️")
                            .font(.custom(Fonts.semibold, size: 36))
                    }
                    .font(.onboardingTitle)
                    .foregroundColor(Colors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                VStack(spacing: 12) {
                    Button {
                        searchQuery = onboardingViewModel.upcomingDestination
                        showDestinationSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Colors.secondaryText)
                            
                            Text(onboardingViewModel.upcomingDestination.isEmpty ? "Where are you going?" : onboardingViewModel.upcomingDestination)
                                .font(.travelBody)
                                .foregroundColor(onboardingViewModel.upcomingDestination.isEmpty ? Colors.secondaryText : Colors.primaryText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        showArrivalPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check-in date")
                                .font(.travelDetail)
                                .foregroundColor(Colors.primaryText)
                            
                            HStack {
                                Text(onboardingViewModel.hasSelectedArrival ? arrivalDateText : "Select check-in date")
                                    .font(.travelBody)
                                    .foregroundColor(onboardingViewModel.hasSelectedArrival ? Colors.primaryText : Colors.secondaryText)
                                
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
                        showDepartingPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Return date")
                                .font(.travelDetail)
                                .foregroundColor(Colors.primaryText)
                            
                            HStack {
                                Text(onboardingViewModel.hasSelectedDeparting ? departingDateText : "Select return date")
                                    .font(.travelBody)
                                    .foregroundColor(onboardingViewModel.hasSelectedDeparting ? Colors.primaryText : Colors.secondaryText)
                                
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
                
                if isDepartingDateInvalid {
                    Text("Return date must be after check-in date.")
                        .font(.travelDetail)
                        .foregroundColor(Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showProfilePicture = true
                } label: {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                
                Button {
                    showProfilePicture = true
                } label: {
                    Text("Skip")
                        .font(.travelDetail)
                        .foregroundColor(Colors.primaryText)
                        .frame(maxWidth: .infinity)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.goBackFont)
                        .foregroundColor(Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .navigationDestination(isPresented: $showProfilePicture) {
            ProfilePictureView()
        }
        .sheet(isPresented: $showDestinationSheet, onDismiss: {
            searchResults = []
            searchTask?.cancel()
        }) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Colors.secondaryText)
                        
                        TextField("Search", text: $searchQuery)
                            .font(.travelBody)
                            .foregroundColor(Colors.primaryText)
                            .onSubmit {
                                runSearch(for: searchQuery)
                            }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Colors.secondaryText.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results")
                            .font(.travelDetail)
                            .foregroundColor(Colors.primaryText)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(searchResults) { result in
                                    Button {
                                        searchTask?.cancel()
                                        searchResults = []
                                        onboardingViewModel.upcomingDestination = result.title
                                        showDestinationSheet = false
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.travelBody)
                                                .foregroundColor(Colors.primaryText)
                                            
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.travelDetail)
                                                    .foregroundColor(Colors.secondaryText)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 20)
                                        .padding(.horizontal, 16)
                                        .background(Colors.card)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showArrivalPicker) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        
                        Button("Done") {
                            showArrivalPicker = false
                        }
                        .font(.travelDetail)
                        .foregroundColor(Colors.accent)
                    }
                    
                    DatePicker("", selection: $onboardingViewModel.arrivalDate, in: minimumDate..., displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(Colors.accent)
                        .onChange(of: onboardingViewModel.arrivalDate) {
                            onboardingViewModel.hasSelectedArrival = true
                        }
                }
                .padding(20)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showDepartingPicker) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        
                        Button("Done") {
                            showDepartingPicker = false
                        }
                        .font(.travelDetail)
                        .foregroundColor(Colors.accent)
                    }
                    
                    DatePicker("", selection: $onboardingViewModel.departingDate, in: (onboardingViewModel.hasSelectedArrival ? onboardingViewModel.arrivalDate : minimumDate)..., displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(Colors.accent)
                        .onChange(of: onboardingViewModel.departingDate) {
                            onboardingViewModel.hasSelectedDeparting = true
                        }
                }
                .padding(20)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.light)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func runSearch(for query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            let places = await searchPlaces(matching: trimmed)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                searchResults = places
            }
        }
    }
    
    private func searchPlaces(matching query: String) async -> [UpcomingMapboxPlace] {
        guard
            let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String,
            !accessToken.isEmpty,
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else {
            return []
        }
        
        var components = URLComponents(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encodedQuery).json")
        components?.queryItems = [
            URLQueryItem(name: "types", value: "place,region,country"),
            URLQueryItem(name: "autocomplete", value: "true"),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        guard let url = components?.url else {
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(UpcomingMapboxGeocodingResponse.self, from: data)
            return response.features
        } catch {
            return []
        }
    }
}

private struct UpcomingMapboxGeocodingResponse: Decodable {
    let features: [UpcomingMapboxPlace]
}

private struct UpcomingMapboxPlace: Identifiable, Decodable {
    let id: String
    let placeName: String
    let properties: UpcomingMapboxProperties?
    private let contextCode: String?
    
    var title: String {
        let city = placeComponents.first ?? placeName
        let flag = Self.flagEmoji(for: countryCode)
        return flag.isEmpty ? city : "\(flag) \(city)"
    }
    
    var subtitle: String {
        let remaining = placeComponents.dropFirst()
        guard !remaining.isEmpty else { return "" }
        return remaining.joined(separator: ", ")
    }
    
    private var countryCode: String {
        let propertyCode = properties?
            .shortCode?
            .uppercased()
            .split(separator: "-")
            .first
            .map(String.init) ?? ""
        
        return propertyCode.isEmpty ? (contextCode?.uppercased() ?? "") : propertyCode
    }
    
    private var placeComponents: [String] {
        placeName
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private static func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        return code.uppercased().unicodeScalars.compactMap { scalar in
            guard let flagScalar = UnicodeScalar(base + scalar.value) else { return nil }
            return String(flagScalar)
        }
        .joined()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case properties
        case context
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        placeName = try container.decode(String.self, forKey: .placeName)
        
        properties = try container.decodeIfPresent(UpcomingMapboxProperties.self, forKey: .properties)
        
        let contexts = try container.decodeIfPresent([UpcomingMapboxContext].self, forKey: .context) ?? []
        contextCode = contexts.first(where: { $0.id.hasPrefix("country") })?.shortCode?.split(separator: "-").first.map(String.init)
    }
}

private struct UpcomingMapboxContext: Decodable {
    let id: String
    let shortCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case shortCode = "short_code"
    }
}

private struct UpcomingMapboxProperties: Decodable {
    let shortCode: String?
    
    enum CodingKeys: String, CodingKey {
        case shortCode = "short_code"
    }
}

#Preview {
    UpcomingTripsView()
        .environmentObject(OnboardingViewModel())
}
