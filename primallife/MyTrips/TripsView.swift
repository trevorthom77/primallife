import SwiftUI

struct TripsView: View {
    @State private var destination = ""
    @State private var searchQuery = ""
    @State private var checkInDate = Date()
    @State private var returnDate = Date()
    @State private var hasCheckInDate = false
    @State private var hasReturnDate = false
    @State private var isShowingDestinationSheet = false
    @State private var activeDatePicker: DatePickerType?
    @State private var searchResults: [MapboxPlace] = []
    @State private var searchTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss
    private let searchColor = Colors.primaryText
    
    private var isAddTripEnabled: Bool {
        !destination.isEmpty && hasCheckInDate && hasReturnDate && returnDate >= checkInDate
    }
    
    private enum DatePickerType {
        case checkIn
        case returnDate
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    BackButton {
                        dismiss()
                    }
                    
                    Spacer()
                }
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Colors.card)
                    .frame(height: 160)
                    .overlay {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Add Trip")
                                .font(.customTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            Button {
                                searchQuery = destination
                                isShowingDestinationSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Text(destination.isEmpty ? "Search" : destination)
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Colors.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .padding(.top, 12)
                    }
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Colors.card)
                    .overlay {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Dates")
                                .font(.customTitle)
                                .foregroundStyle(Colors.primaryText)
                            
                            VStack(spacing: 12) {
                                Button {
                                    activeDatePicker = .checkIn
                                } label: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Colors.accent.opacity(0.1))
                                        .frame(height: 48)
                                        .overlay(alignment: .leading) {
                                            Text(hasCheckInDate ? formattedDate(checkInDate) : "Check in Date")
                                                .font(.travelBody)
                                                .foregroundStyle(searchColor)
                                                .padding(.leading, 12)
                                        }
                                        .contentShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    activeDatePicker = .returnDate
                                } label: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Colors.accent.opacity(0.1))
                                        .frame(height: 48)
                                        .overlay(alignment: .leading) {
                                            Text(hasReturnDate ? formattedDate(returnDate) : "Return Date")
                                                .font(.travelBody)
                                                .foregroundStyle(searchColor)
                                                .padding(.leading, 12)
                                        }
                                        .contentShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .frame(height: 220)
                
                Button {
                } label: {
                    Text("Add Trip")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isAddTripEnabled ? Colors.accent : Colors.accent.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!isAddTripEnabled)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShowingDestinationSheet, onDismiss: {
            searchResults = []
            searchTask?.cancel()
        }) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Colors.primaryText)
                        
                        TextField("Search", text: $searchQuery)
                            .font(.travelBody)
                            .foregroundStyle(Colors.primaryText)
                            .onSubmit {
                                runSearch(for: searchQuery)
                            }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Colors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(searchResults) { result in
                                    Button {
                                        searchTask?.cancel()
                                        searchResults = []
                                        destination = result.title
                                        isShowingDestinationSheet = false
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.travelBody)
                                                .foregroundStyle(Colors.primaryText)
                                            
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.travelDetail)
                                                    .foregroundStyle(Colors.secondaryText)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 20)
                                        .padding(.horizontal, 16)
                                        .background(Colors.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .overlay {
            if let picker = activeDatePicker {
                ZStack(alignment: .bottom) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            activeDatePicker = nil
                        }
                    
                    datePickerOverlay(for: picker)
                }
            }
        }
    }
    
    @ViewBuilder
    private func datePickerOverlay(for type: DatePickerType) -> some View {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 32,
                topTrailing: 32
            )
        )
        .fill(Colors.card)
        .frame(height: 560)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            VStack(spacing: 16) {
                DatePicker(
                    "",
                    selection: dateBinding(for: type),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Colors.accent)
                
                Button {
                    confirmDate(for: type)
                } label: {
                    Text("Done")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .bottom)
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
    
    private func searchPlaces(matching query: String) async -> [MapboxPlace] {
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
            let response = try JSONDecoder().decode(MapboxGeocodingResponse.self, from: data)
            return response.features
        } catch {
            return []
        }
    }
}

private struct MapboxGeocodingResponse: Decodable {
    let features: [MapboxPlace]
}

private struct MapboxPlace: Identifiable, Decodable {
    let id: String
    let placeName: String
    let properties: MapboxProperties?
    private let contextCode: String?
    
    var displayName: String {
        let flag = countryCode.flagEmoji
        return flag.isEmpty ? placeName : "\(flag) \(placeName)"
    }
    
    var title: String {
        let city = placeComponents.first ?? placeName
        let flag = countryCode.flagEmoji
        return flag.isEmpty ? city : "\(flag) \(city)"
    }
    
    var plainTitle: String {
        placeComponents.first ?? placeName
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
        
        properties = try container.decodeIfPresent(MapboxProperties.self, forKey: .properties)
        
        let contexts = try container.decodeIfPresent([MapboxContext].self, forKey: .context) ?? []
        contextCode = contexts.first(where: { $0.id.hasPrefix("country") })?.shortCode?.split(separator: "-").first.map(String.init)
    }
}

private struct MapboxContext: Decodable {
    let id: String
    let shortCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case shortCode = "short_code"
    }
}

private struct MapboxProperties: Decodable {
    let shortCode: String?
    
    enum CodingKeys: String, CodingKey {
        case shortCode = "short_code"
    }
}

private extension String {
    var flagEmoji: String {
        let base: UInt32 = 127397
        return self.uppercased().unicodeScalars.compactMap { scalar in
            guard let flagScalar = UnicodeScalar(base + scalar.value) else { return nil }
            return String(flagScalar)
        }
        .joined()
    }
}
