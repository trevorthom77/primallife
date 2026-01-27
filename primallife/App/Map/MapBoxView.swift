//
//  MapBoxView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI
import Foundation
import UIKit
import Combine
import CoreLocation
import MapboxMaps
import Supabase

private let mapTripsDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let mapTripsTimestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let mapTripsTimestampFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

struct MapBoxView: View {
    @Binding var hideChrome: Bool
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.supabaseClient) private var supabase
    @AppStorage("mapSavedDestinationLatitude") private var savedDestinationLatitude: Double = 0
    @AppStorage("mapSavedDestinationLongitude") private var savedDestinationLongitude: Double = 0
    @AppStorage("mapHasSavedDestination") private var hasSavedDestination = false
    @State private var isShowingSearch = false
    @State private var isShowingProfile = false
    @State private var isShowingFilters = false
    @State private var viewport: Viewport = .styleDefault
    @State private var selectedPlace: MapboxPlace?
    @State private var placeImageURL: URL?
    @State private var photoTask: Task<Void, Never>?
    @State private var selectedPlaceTravelerCount = 0
    @StateObject private var locationManager = UserLocationManager()
    @State private var userCoordinate: CLLocationCoordinate2D?
    @State private var userLocationName = ""
    @State private var userLocationFlag = ""
    @State private var isUsingSelectedDestination = false
    @State private var hasCenteredOnUser = false
    @State private var airplaneFeedbackToggle = false
    @State private var flyFeedbackToggle = false
    @State private var otherUserLocations: [OtherUserLocation] = []
    @State private var nearbyTravelers: [MapTraveler] = []
    @State private var locationsRefreshTask: Task<Void, Never>?
    @State private var minAgeFilter: Int?
    @State private var maxAgeFilter: Int?
    @State private var selectedCountryID: String?
    @State private var selectedGender = "All"
    @State private var selectedTravelDescription: String?
    @State private var selectedInterests: Set<String> = []
    @State private var isLoadingLocations = false
    @State private var loadingFeedbackToggle = false
    @State private var suppressLoadingFeedback = true
    @StateObject private var travelerImageStore = TravelerImageStore()
    private let defaultMapCenterCoordinate = CLLocationCoordinate2D(latitude: 9.9333, longitude: -84.0833)
    private let otherUserJitterRadius: CLLocationDistance = 500
    private let fixedLocationQueryRadiusMeters: CLLocationDistance = 10 * 1609.344
    
    private let customPlaceImageNames = [
        "italy",
        "greece",
        "puerto rico",
        "costa rica",
        "australia",
        "jamaica",
        "switzerland"
    ]

    private var userAvatarURL: URL? {
        profileStore.profile?.avatarURL(using: supabase)
    }

    private var isAgeFilterActive: Bool {
        minAgeFilter != nil || maxAgeFilter != nil
    }

    private var isOriginFilterActive: Bool {
        selectedCountryID != nil
    }

    private var isGenderFilterActive: Bool {
        selectedGender != "All"
    }

    private var normalizedTravelDescriptionFilter: String? {
        guard let selectedTravelDescription else { return nil }
        let trimmed = selectedTravelDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var isTravelDescriptionFilterActive: Bool {
        normalizedTravelDescriptionFilter != nil
    }

    private var isInterestsFilterActive: Bool {
        !selectedInterests.isEmpty
    }

    private var filteredTravelers: [MapTraveler] {
        let travelDescriptionFilter = normalizedTravelDescriptionFilter
        let interestsFilter = selectedInterests

        return nearbyTravelers.filter { traveler in
            if isAgeFilterActive {
                guard let age = traveler.age else { return false }
                if let minAgeFilter, age < minAgeFilter { return false }
                if let maxAgeFilter, age > maxAgeFilter { return false }
            }
            if let selectedCountryID {
                guard traveler.origin == selectedCountryID else { return false }
            }
            if isGenderFilterActive {
                guard let gender = traveler.gender?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !gender.isEmpty else { return false }
                guard gender.localizedCaseInsensitiveCompare(selectedGender) == .orderedSame else { return false }
            }
            if let travelDescriptionFilter {
                guard let travelDescription = traveler.travelDescription?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                    !travelDescription.isEmpty else {
                    return false
                }
                guard travelDescription.localizedCaseInsensitiveCompare(travelDescriptionFilter) == .orderedSame else {
                    return false
                }
            }
            if !interestsFilter.isEmpty {
                guard traveler.interests.contains(where: { interestsFilter.contains($0) }) else {
                    return false
                }
            }
            return true
        }
    }

    private var filteredOtherUserLocations: [OtherUserLocation] {
        guard isAgeFilterActive
                || isOriginFilterActive
                || isGenderFilterActive
                || isTravelDescriptionFilterActive
                || isInterestsFilterActive else {
            return otherUserLocations
        }
        let allowedIDs = Set(filteredTravelers.map(\.id))
        return otherUserLocations.filter { allowedIDs.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(viewport: $viewport) {
                    if let coordinate = userCoordinate {
                        MapViewAnnotation(coordinate: coordinate) {
                            userLocationAnnotation
                        }
                        .priority(1)
                    }
                    
                    ForEvery(filteredOtherUserLocations) { location in
                        MapViewAnnotation(coordinate: location.coordinate) {
                            if let userID = UUID(uuidString: location.id) {
                                NavigationLink {
                                    OthersProfileView(userID: userID)
                                } label: {
                                    otherUserAnnotation(for: location)
                                }
                                .buttonStyle(.plain)
                            } else {
                                otherUserAnnotation(for: location)
                            }
                        }
                        .allowOverlap(true)
                    }
                }
                    .ornamentOptions(
                        OrnamentOptions(
                            scaleBar: ScaleBarViewOptions(
                                position: .topLeading,
                                margins: .zero,
                                visibility: .hidden,
                                useMetricUnits: true
                            ),
                            compass: CompassViewOptions(
                                visibility: .hidden
                            )
                        )
                    )
                    .mapStyle(
                        MapStyle(
                            uri: StyleURI(
                                rawValue: "mapbox://styles/trevorthom7/cmi6lppz6001i01sachln4nbu"
                            )!
                        )
                    )
                    .cameraBounds(
                        CameraBoundsOptions(
                            minZoom: 3.0
                        )
                    )
                    .sensoryFeedback(.impact(weight: .medium), trigger: loadingFeedbackToggle)
                    .overlay(alignment: .top) {
                        if !hideChrome {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        isShowingProfile = true
                                    }) {
                                        avatarButtonImage
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                    }
                                    
                                    Button(action: {
                                        isShowingSearch = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "magnifyingglass")
                                                .foregroundStyle(Colors.secondaryText)

                                            if !userLocationName.isEmpty, !userLocationFlag.isEmpty {
                                                Text(userLocationFlag)
                                                    .font(.travelBody)
                                                    .foregroundStyle(Colors.primaryText)
                                                    .lineLimit(1)
                                            }
                                            
                                            Text(userLocationName.isEmpty ? "Search" : userLocationName)
                                                .font(.travelBody)
                                                .foregroundStyle(Colors.primaryText)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 16)
                                        .background(Colors.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }

                                Button(action: {
                                    isShowingFilters = true
                                }) {
                                    Text("Filter")
                                        .font(.travelBodySemibold)
                                        .foregroundStyle(Colors.primaryText)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Colors.card)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 58)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if !hideChrome {
                            VStack(spacing: 12) {
                                Button(action: {
                                    airplaneFeedbackToggle.toggle()
                                    guard let coordinate = userCoordinate, let camera = proxy.camera else { return }
                                    camera.fly(
                                        to: CameraOptions(
                                            center: coordinate,
                                            zoom: 8,
                                            pitch: 0
                                        ),
                                        duration: 2
                                    )
                                }) {
                                    Circle()
                                        .fill(Colors.card)
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            Image("location")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                                .foregroundStyle(Colors.primaryText)
                                        }
                                }
                                .sensoryFeedback(.impact(weight: .medium), trigger: airplaneFeedbackToggle)
                                .buttonStyle(.plain)
                            }
                            .padding(.trailing)
                            .padding(.top, 122)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if selectedPlace != nil {
                            BackButton {
                                selectedPlace = nil
                                placeImageURL = nil
                                photoTask?.cancel()
                                hideChrome = false
                            }
                            .padding(.leading)
                            .padding(.top, 58)
                        }
                    }
                    .overlay(alignment: .top) {
                        if isLoadingLocations {
                            loadingIndicator
                                .padding(.top, hideChrome ? 58 : 120)
                                .padding(.horizontal)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if let place = selectedPlace {
                            UnevenRoundedRectangle(
                                cornerRadii: RectangleCornerRadii(
                                    topLeading: 32,
                                    topTrailing: 32
                                )
                            )
                            .fill(Colors.card)
                            .frame(height: 440)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .top) {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(place.primaryName)
                                                .font(.travelTitle)
                                                .foregroundStyle(Colors.primaryText)
                                            
                                            if !place.countryDisplay.isEmpty {
                                                Text(place.countryDisplay)
                                                    .font(.travelBody)
                                                    .foregroundStyle(Colors.secondaryText)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: -8) {
                                            Image("profile4")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 36, height: 36)
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }
                                            
                                            Image("profile5")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 36, height: 36)
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }
                                            
                                            Image("profile6")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 36, height: 36)
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }
                                            
                                            Image("profile9")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 36, height: 36)
                                                .clipShape(Circle())
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }
                                            
                                            ZStack {
                                                Circle()
                                                    .fill(Colors.background)
                                                    .frame(width: 36, height: 36)
                                                    .overlay {
                                                        Circle()
                                                            .stroke(Colors.card, lineWidth: 3)
                                                    }
                                                
                                                Text("\(selectedPlaceTravelerCount)+")
                                                    .font(.custom(Fonts.semibold, size: 12))
                                                    .foregroundStyle(Colors.primaryText)
                                            }
                                        }
                                    }
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Colors.secondaryText.opacity(0.12))
                                        
                                        if let customImageName = customImageName(for: place) {
                                            Image(customImageName)
                                                .resizable()
                                                .scaledToFill()
                                        } else if let imageURL = placeImageURL {
                                            AsyncImage(url: imageURL) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 170)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    
                                    Text("5,343 miles away")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Button(action: {
                                        flyFeedbackToggle.toggle()
                                        handleFly(to: place, camera: proxy.camera)
                                    }) {
                                        Text("Fly")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.tertiaryText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 18)
                                    }
                                    .sensoryFeedback(.impact(weight: .medium), trigger: flyFeedbackToggle)
                                    .background(Colors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 28)
                            }
                            .ignoresSafeArea(edges: .bottom)
                            .onTapGesture {
                                selectedPlace = nil
                                placeImageURL = nil
                                photoTask?.cancel()
                                hideChrome = false
                            }
                        }
                        if selectedPlace == nil {
                            MapCommunityPanel(
                                travelers: filteredTravelers,
                                travelerImageStore: travelerImageStore
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 120)
                        }
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        applySavedDestination(using: proxy.camera)
                        applyInitialZoom()
                        locationManager.requestPermission()
                        suppressLoadingFeedback = true
                    }
                    .onReceive(locationManager.$coordinate) { coordinate in
                        if let coordinate {
                            Task {
                                await upsertUserLocation(coordinate)
                            }
                            loadLocations(for: coordinate)
                        }
                        
                        guard !isUsingSelectedDestination else { return }
                        userCoordinate = coordinate
                        if let coordinate {
                            resolveUserLocationName(for: coordinate)
                        } else {
                            userLocationName = ""
                            userLocationFlag = ""
                        }
                        
                        guard !hasCenteredOnUser, let coordinate else { return }
                        viewport = .camera(
                            center: coordinate,
                            zoom: 8,
                            bearing: 0,
                            pitch: 0
                        )
                        hasCenteredOnUser = true
                    }
                    .task(id: selectedPlace?.id) {
                        selectedPlaceTravelerCount = 0
                        guard let place = selectedPlace else { return }
                        selectedPlaceTravelerCount = await fetchSelectedPlaceTravelerCount(for: place)
                    }
                    .sheet(isPresented: $isShowingSearch) {
                        MapSearchSheet { place in
                            selectedPlace = place
                            placeImageURL = nil
                            photoTask?.cancel()
                            loadImage(for: place)
                            hideChrome = true
                            isShowingSearch = false
                            guard let coordinate = place.coordinate, let camera = proxy.camera else { return }
                            let offsetLatitude = min(90, max(-90, coordinate.latitude - 1.0))
                            let adjustedCoordinate = CLLocationCoordinate2D(latitude: offsetLatitude, longitude: coordinate.longitude)
                            camera.fly(
                                to: CameraOptions(
                                    center: adjustedCoordinate,
                                    zoom: 7,
                                    pitch: 0
                                ),
                                duration: 5
                            )
                        }
                    }
                    .onDisappear {
                        stopLocationsRefresh()
                    }
            }
            .navigationDestination(isPresented: $isShowingProfile) {
                profileDestination
            }
            .navigationDestination(isPresented: $isShowingFilters) {
                FiltersView(
                    minAge: $minAgeFilter,
                    maxAge: $maxAgeFilter,
                    selectedGender: $selectedGender,
                    selectedCountryID: $selectedCountryID,
                    selectedTravelDescription: $selectedTravelDescription,
                    selectedInterests: $selectedInterests
                )
            }
        }
    }

    @ViewBuilder
    private var avatarButtonImage: some View {
        let avatarURL = profileStore.profile?.avatarURL(using: supabase)
        
        if let avatarURL,
           let cachedImage = profileStore.cachedAvatarImage,
           profileStore.cachedAvatarURL == avatarURL {
            cachedImage
                .resizable()
                .scaledToFill()
        } else if let avatarURL {
            AsyncImage(url: avatarURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .onAppear {
                            profileStore.cacheAvatar(image, url: avatarURL)
                        }
                } else {
                    placeholderAvatar
                }
            }
        } else {
            placeholderAvatar
        }
    }
    
    private var placeholderAvatar: some View {
        Color.clear
    }
    
    @ViewBuilder
    private var profileDestination: some View {
        if let profile = profileStore.profile {
            ProfileView(
                name: profile.fullName,
                homeCountry: profile.originName ?? "",
                countryFlag: profile.originFlag ?? "",
                tripsCount: 0,
                countriesCount: 0,
                trips: [],
                countries: [],
                tribes: []
            )
        } else if profileStore.isLoading {
            profileLoadingView
        } else if let errorMessage = profileStore.errorMessage {
            profileErrorView(message: errorMessage)
        } else {
            profileLoadingView
        }
    }
    
    private var profileLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Colors.primaryText)
            
            Text("Loading profile...")
                .font(.travelBody)
                .foregroundStyle(Colors.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.background)
    }
    
    private func profileErrorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text("Couldn't load profile")
                .font(.travelTitle)
                .foregroundStyle(Colors.primaryText)
            
            Text(message)
                .font(.travelDetail)
                .foregroundStyle(Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Colors.background)
    }
    
    private func loadImage(for place: MapboxPlace) {
        photoTask?.cancel()
        placeImageURL = nil
        
        let query = place.primaryName.isEmpty ? place.countryName : place.primaryName
        guard !query.isEmpty else { return }
        guard customImageName(for: place) == nil else { return }
        
        photoTask = Task {
            let url = await UnsplashService.fetchImage(for: query)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                placeImageURL = url
            }
        }
    }

    private func customImageName(for place: MapboxPlace) -> String? {
        let candidates = [place.primaryName, place.placeName]
        
        for name in customPlaceImageNames {
            for candidate in candidates where candidate.localizedCaseInsensitiveContains(name) {
                return name
            }
        }
        
        return nil
    }
    
    private func applyDestinationCoordinate(_ coordinate: CLLocationCoordinate2D) {
        isUsingSelectedDestination = true
        userCoordinate = coordinate
        resolveUserLocationName(for: coordinate)
        viewport = .camera(
            center: coordinate,
            zoom: 8,
            bearing: 0,
            pitch: 0
        )
        hasCenteredOnUser = true
        cacheDestinationCoordinate(coordinate)
    }
    
    private func applySavedDestination(using camera: CameraAnimationsManager?) {
        guard hasSavedDestination else { return }
        let coordinate = CLLocationCoordinate2D(
            latitude: savedDestinationLatitude,
            longitude: savedDestinationLongitude
        )
        applyDestinationCoordinate(coordinate)
        camera?.fly(
            to: CameraOptions(
                center: coordinate,
                zoom: 8,
                pitch: 0
            ),
            duration: 0
        )
    }

    private func applyInitialZoom() {
        guard !hasSavedDestination, userCoordinate == nil else { return }
        viewport = .camera(
            center: defaultMapCenterCoordinate,
            zoom: 8,
            bearing: 0,
            pitch: 0
        )
    }
    
    private func cacheDestinationCoordinate(_ coordinate: CLLocationCoordinate2D) {
        hasSavedDestination = true
        savedDestinationLatitude = coordinate.latitude
        savedDestinationLongitude = coordinate.longitude
    }

    private func resolveUserLocationName(for coordinate: CLLocationCoordinate2D) {
        userLocationFlag = ""
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let placemark = placemarks?.first
            let city = placemark?.locality
                ?? placemark?.subAdministrativeArea
                ?? placemark?.administrativeArea
                ?? placemark?.name
            let country = placemark?.country
            let cityName = city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let countryName = country?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let parts = [cityName, countryName].filter { !$0.isEmpty }
            let displayName = parts.joined(separator: ", ")
            guard !displayName.isEmpty else { return }
            DispatchQueue.main.async {
                userLocationName = displayName
            }
        }

        Task {
            let flag = await fetchCountryFlag(for: coordinate)
            guard !flag.isEmpty else { return }
            await MainActor.run {
                userLocationFlag = flag
            }
        }
    }
    
    private func handleFly(to place: MapboxPlace, camera: CameraAnimationsManager?) {
        guard let coordinate = place.coordinate else { return }
        
        selectedPlace = nil
        placeImageURL = nil
        photoTask?.cancel()
        hideChrome = false
        
        applyDestinationCoordinate(coordinate)
        
        camera?.fly(
            to: CameraOptions(
                center: coordinate,
                zoom: 8,
                pitch: 0
            ),
            duration: 2
        )
    }
    
    private func upsertUserLocation(_ coordinate: CLLocationCoordinate2D) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        
        struct LocationUpsert: Encodable {
            let id: String
            let latitude: Double
            let longitude: Double
        }
        
        do {
            try await supabase
                .from("locations")
                .upsert(
                    LocationUpsert(
                        id: userID.uuidString,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    ),
                    onConflict: "id"
                )
                .execute()
        } catch {
            print("Failed to upsert location: \(error.localizedDescription)")
        }
    }

    private func fetchSelectedPlaceTravelerCount(for place: MapboxPlace) async -> Int {
        guard let supabase else { return 0 }

        let destination = place.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else { return 0 }

        struct TripTraveler: Decodable {
            let userID: UUID

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
            }
        }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        let startOfTodayString = mapTripsDateFormatter.string(from: startOfToday)

        do {
            let travelers: [TripTraveler] = try await supabase
                .from("mytrips")
                .select("user_id")
                .eq("destination", value: destination)
                .gte("return_date", value: startOfTodayString)
                .execute()
                .value

            var uniqueUserIDs = Set(travelers.map { $0.userID })
            if let currentUserID = supabase.auth.currentUser?.id {
                uniqueUserIDs.remove(currentUserID)
            }
            return uniqueUserIDs.count
        } catch {
            return 0
        }
    }

    private func travelerAge(from birthday: String?) -> Int? {
        guard let birthday, !birthday.isEmpty else { return nil }

        let birthDate = mapTripsTimestampFormatterWithFractional.date(from: birthday)
            ?? mapTripsTimestampFormatter.date(from: birthday)
            ?? mapTripsDateFormatter.date(from: birthday)
        guard let birthDate else { return nil }

        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    private func fetchBlockedUserIDs(for userID: UUID, supabase: SupabaseClient) async throws -> Set<String> {
        let outgoing: [BlockedUserRow] = try await supabase
            .from("blocks")
            .select("blocked_id")
            .eq("blocker_id", value: userID.uuidString)
            .execute()
            .value

        let incoming: [BlockingUserRow] = try await supabase
            .from("blocks")
            .select("blocker_id")
            .eq("blocked_id", value: userID.uuidString)
            .execute()
            .value

        let outgoingIDs = outgoing.map { $0.blockedID.lowercased() }
        let incomingIDs = incoming.map { $0.blockerID.lowercased() }
        return Set(outgoingIDs + incomingIDs)
    }

    private func fetchOtherLocations(around coordinate: CLLocationCoordinate2D) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let radius = fixedLocationQueryRadiusMeters
        
        let bounds = nearbyBounds(around: coordinate, radius: radius)
        let originLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let rows: [UserLocation] = try await supabase
                .from("locations")
                .select()
                .neq("id", value: userID.uuidString)
                .gte("latitude", value: bounds.minLatitude)
                .lte("latitude", value: bounds.maxLatitude)
                .gte("longitude", value: bounds.minLongitude)
                .lte("longitude", value: bounds.maxLongitude)
                .execute()
                .value
            
            let nearbyRows = rows.filter { row in
                let location = CLLocation(latitude: row.latitude, longitude: row.longitude)
                return location.distance(from: originLocation) <= radius
            }
            
            guard !nearbyRows.isEmpty else {
                await MainActor.run {
                    otherUserLocations = []
                    nearbyTravelers = []
                }
                return
            }

            let blockedUserIDs = try await fetchBlockedUserIDs(for: userID, supabase: supabase)
            let visibleRows = nearbyRows.filter { !blockedUserIDs.contains($0.id.lowercased()) }

            guard !visibleRows.isEmpty else {
                await MainActor.run {
                    otherUserLocations = []
                    nearbyTravelers = []
                }
                return
            }
            
            let ids = visibleRows.map { $0.id }
            
            let travelers: [TravelerRow] = try await supabase
                .from("onboarding")
                .select("id, avatar_url, full_name, origin, birthday, gender, travel_description, interests")
                .in("id", values: ids)
                .execute()
                .value
            
            let travelerLookup = Dictionary(uniqueKeysWithValues: travelers.map { ($0.id, $0) })
            let distanceByID = Dictionary(uniqueKeysWithValues: visibleRows.map { row in
                let location = CLLocation(latitude: row.latitude, longitude: row.longitude)
                let distanceMiles = location.distance(from: originLocation) / 1609.344
                return (row.id, distanceMiles)
            })
            
            await MainActor.run {
                otherUserLocations = visibleRows.map { row in
                    let traveler = travelerLookup[row.id]
                    let jittered = jitteredCoordinate(
                        for: CLLocationCoordinate2D(latitude: row.latitude, longitude: row.longitude),
                        userID: row.id
                    )
                    return OtherUserLocation(
                        id: row.id,
                        latitude: jittered.latitude,
                        longitude: jittered.longitude,
                        avatarPath: traveler?.avatarPath
                    )
                }

                nearbyTravelers = visibleRows.compactMap { row in
                    guard let traveler = travelerLookup[row.id] else { return nil }
                    return MapTraveler(
                        id: row.id,
                        name: traveler.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                        origin: traveler.origin?.trimmingCharacters(in: .whitespacesAndNewlines),
                        avatarPath: traveler.avatarPath,
                        distanceMiles: distanceByID[row.id],
                        age: travelerAge(from: traveler.birthday),
                        gender: traveler.gender?.trimmingCharacters(in: .whitespacesAndNewlines),
                        travelDescription: traveler.travelDescription?
                            .trimmingCharacters(in: .whitespacesAndNewlines),
                        interests: traveler.interests ?? []
                    )
                }
            }
        } catch {
            print("Failed to fetch other locations: \(error.localizedDescription)")
        }
    }

    private func fetchCountryFlag(for coordinate: CLLocationCoordinate2D) async -> String {
        guard
            let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String,
            !accessToken.isEmpty
        else {
            return ""
        }

        let coordinateString = "\(coordinate.longitude),\(coordinate.latitude)"
        var components = URLComponents(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/\(coordinateString).json")
        components?.queryItems = [
            URLQueryItem(name: "types", value: "country"),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "access_token", value: accessToken)
        ]

        guard let url = components?.url else { return "" }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MapboxGeocodingResponse.self, from: data)
            return response.features.first?.flagEmoji ?? ""
        } catch {
            return ""
        }
    }
    
    private func nearbyBounds(around coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) -> (minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        let metersPerDegreeLatitude: Double = 111_000
        let latDelta = radius / metersPerDegreeLatitude
        let longitudeScale = max(0.0001, abs(cos(coordinate.latitude * .pi / 180)))
        let lonDelta = radius / (metersPerDegreeLatitude * longitudeScale)
        
        let minLatitude = max(-90, coordinate.latitude - latDelta)
        let maxLatitude = min(90, coordinate.latitude + latDelta)
        let minLongitude = max(-180, coordinate.longitude - lonDelta)
        let maxLongitude = min(180, coordinate.longitude + lonDelta)
        
        return (minLatitude, maxLatitude, minLongitude, maxLongitude)
    }

    private func jitteredCoordinate(for coordinate: CLLocationCoordinate2D, userID: String) -> CLLocationCoordinate2D {
        let seed = stableHash64(userID)
        let angleSeed = Double(UInt32(truncatingIfNeeded: seed)) / Double(UInt32.max)
        let distanceSeed = Double(UInt32(truncatingIfNeeded: seed >> 32)) / Double(UInt32.max)
        let angle = angleSeed * 2 * .pi
        let distance = sqrt(distanceSeed) * otherUserJitterRadius
        let metersPerDegreeLatitude: Double = 111_000
        let longitudeScale = max(0.0001, abs(cos(coordinate.latitude * .pi / 180)))
        let x = distance * cos(angle)
        let y = distance * sin(angle)
        let latDelta = y / metersPerDegreeLatitude
        let lonDelta = x / (metersPerDegreeLatitude * longitudeScale)
        let latitude = min(90, max(-90, coordinate.latitude + latDelta))
        let longitude = min(180, max(-180, coordinate.longitude + lonDelta))
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func stableHash64(_ string: String) -> UInt64 {
        let prime: UInt64 = 1099511628211
        var hash: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
    
    private func loadLocations(for coordinate: CLLocationCoordinate2D) {
        locationsRefreshTask?.cancel()
        if !suppressLoadingFeedback {
            isLoadingLocations = true
            loadingFeedbackToggle.toggle()
        }
        locationsRefreshTask = Task {
            await fetchOtherLocations(around: coordinate)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isLoadingLocations = false
                suppressLoadingFeedback = false
            }
        }
    }
    
    private func stopLocationsRefresh() {
        locationsRefreshTask?.cancel()
        locationsRefreshTask = nil
        isLoadingLocations = false
    }

    private var loadingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Colors.primaryText)

            Text("Loading...")
                .font(.travelDetail)
                .foregroundStyle(Colors.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Colors.card)
        .clipShape(Capsule())
    }
    
    private var userLocationAnnotation: some View {
        let outerSize: CGFloat = 66
        let innerSize: CGFloat = 58
        let strokeWidth: CGFloat = 4

        return ZStack {
            Circle()
                .fill(Colors.card)
                .frame(width: outerSize, height: outerSize)
            
            let avatarURL = userAvatarURL
            
            Group {
                if let avatarURL,
                   let cachedImage = profileStore.cachedAvatarImage,
                   profileStore.cachedAvatarURL == avatarURL {
                    cachedImage
                        .resizable()
                        .scaledToFill()
                } else if let avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .onAppear {
                                    profileStore.cacheAvatar(image, url: avatarURL)
                                }
                        } else {
                            Colors.secondaryText.opacity(0.3)
                        }
                    }
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
            .frame(width: innerSize, height: innerSize)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Colors.card, lineWidth: strokeWidth)
            }
        }
    }
    
    private func otherUserAnnotation(for location: OtherUserLocation) -> some View {
        ZStack {
            Circle()
                .fill(Colors.card)
                .frame(width: 66, height: 66)
            
            let avatarURL = location.avatarURL(using: supabase)

            Group {
                if let avatarURL {
                    if let cachedImage = travelerImageStore.image(for: avatarURL) {
                        cachedImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        Colors.secondaryText.opacity(0.3)
                    }
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
            .task(id: avatarURL) {
                if let avatarURL {
                    travelerImageStore.loadImage(for: avatarURL)
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Colors.card, lineWidth: 4)
            }
        }
    }
}

private struct UserLocation: Identifiable, Decodable {
    let id: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct BlockedUserRow: Decodable {
    let blockedID: String

    enum CodingKeys: String, CodingKey {
        case blockedID = "blocked_id"
    }
}

private struct BlockingUserRow: Decodable {
    let blockerID: String

    enum CodingKeys: String, CodingKey {
        case blockerID = "blocker_id"
    }
}

private struct TravelerRow: Decodable {
    let id: String
    let avatarPath: String?
    let fullName: String?
    let origin: String?
    let birthday: String?
    let gender: String?
    let travelDescription: String?
    let interests: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case avatarPath = "avatar_url"
        case fullName = "full_name"
        case origin
        case birthday
        case gender
        case travelDescription = "travel_description"
        case interests
    }
}

private struct MapTraveler: Identifiable {
    let id: String
    let name: String
    let origin: String?
    let avatarPath: String?
    let distanceMiles: Double?
    let age: Int?
    let gender: String?
    let travelDescription: String?
    let interests: [String]
    
    var originDisplay: String? {
        guard let origin, !origin.isEmpty,
              let country = CountryDatabase.all.first(where: { $0.id == origin }),
              !country.flag.isEmpty
        else {
            return nil
        }
        return country.flag
    }

    func avatarURL(using supabase: SupabaseClient?) -> URL? {
        guard let supabase, let avatarPath else { return nil }

        do {
            return try supabase.storage
                .from("profile-photos")
                .getPublicURL(path: avatarPath)
        } catch {
            return nil
        }
    }
}

private struct OtherUserLocation: Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let avatarPath: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func avatarURL(using supabase: SupabaseClient?) -> URL? {
        guard let supabase, let avatarPath else { return nil }
        
        do {
            return try supabase.storage
                .from("profile-photos")
                .getPublicURL(path: avatarPath)
        } catch {
            return nil
        }
    }
}

private enum MapTravelerImageCache {
    static var images: [URL: Image] = [:]
}

@MainActor
private final class TravelerImageStore: ObservableObject {
    @Published private(set) var images: [URL: Image] = MapTravelerImageCache.images
    private var inFlight: Set<URL> = []

    func image(for url: URL) -> Image? {
        images[url]
    }

    func loadImage(for url: URL) {
        guard images[url] == nil, !inFlight.contains(url) else { return }
        inFlight.insert(url)

        Task {
            defer { inFlight.remove(url) }
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let uiImage = UIImage(data: data) else { return }
                let image = Image(uiImage: uiImage)
                images[url] = image
                MapTravelerImageCache.images[url] = image
            } catch { }
        }
    }
}

private struct MapCommunityPanel: View {
    @Environment(\.supabaseClient) private var supabase
    let travelers: [MapTraveler]
    @ObservedObject var travelerImageStore: TravelerImageStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if travelers.isEmpty {
                HStack {
                    Spacer()
                    Text("No travelers nearby yet.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                    Spacer()
                }
                .frame(height: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(travelers) { traveler in
                            if let userID = UUID(uuidString: traveler.id) {
                                NavigationLink {
                                    OthersProfileView(userID: userID)
                                } label: {
                                    travelerCard(traveler)
                                }
                                .buttonStyle(.plain)
                            } else {
                                travelerCard(traveler)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func travelerCard(_ traveler: MapTraveler) -> some View {
        HStack(spacing: 12) {
            travelerImage(for: traveler)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 6) {
                if !traveler.name.isEmpty {
                    if let age = traveler.age {
                        HStack(spacing: 4) {
                            Text(traveler.name)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.primaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text("\(age)")
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    } else {
                        Text(traveler.name)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                if traveler.originDisplay != nil || traveler.distanceMiles != nil {
                    HStack(spacing: 8) {
                        if let originDisplay = traveler.originDisplay {
                            Text(originDisplay)
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if let distanceMiles = traveler.distanceMiles {
                            Text(String(format: "%.1f mi", distanceMiles))
                                .font(.travelDetail)
                                .foregroundStyle(Colors.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .frame(width: 220, alignment: .leading)
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func travelerImage(for traveler: MapTraveler) -> some View {
        if let avatarURL = traveler.avatarURL(using: supabase) {
            Group {
                if let cachedImage = travelerImageStore.image(for: avatarURL) {
                    cachedImage
                        .resizable()
                        .scaledToFill()
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
            .task(id: avatarURL) {
                travelerImageStore.loadImage(for: avatarURL)
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }
}

private final class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            coordinate = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
#Preview("Map") {
    MapBoxView(hideChrome: .constant(false))
        .environmentObject(ProfileStore())
}

private struct MapSearchSheet: View {
    @State private var searchText = ""
    @State private var results: [MapboxPlace] = []
    @State private var searchTask: Task<Void, Never>?
    let onPlaceSelected: (MapboxPlace) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Colors.secondaryText)
                
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                    }
                    
                    TextField("", text: $searchText)
                        .font(.travelBody)
                        .foregroundStyle(Colors.primaryText)
                        .onSubmit {
                            runSearch()
                        }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Colors.secondaryText.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Text("Results")
                .font(.travelDetail)
                .foregroundStyle(Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(results) { result in
                        Button {
                            onPlaceSelected(result)
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
                            .padding(.vertical, 28)
                            .padding(.horizontal, 24)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .background(Colors.background)
    }
    
    private func runSearch() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            results = []
            return
        }
        
        searchTask = Task {
            let cities = await searchCities(matching: query)
            await MainActor.run {
                results = cities
            }
        }
    }
    
    private func searchCities(matching query: String) async -> [MapboxPlace] {
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
    let countryCode: String?
    let properties: MapboxProperties?
    let center: [Double]
    
    var coordinate: CLLocationCoordinate2D? {
        guard center.count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: center[1], longitude: center[0])
    }
    
    var flagEmoji: String {
        guard let countryCode else { return "" }
        return countryCode.flagEmoji
    }
    
    var displayName: String {
        flagEmoji.isEmpty ? placeName : "\(flagEmoji) \(placeName)"
    }
    
    var title: String {
        let city = placeComponents.first ?? placeName
        return flagEmoji.isEmpty ? city : "\(flagEmoji) \(city)"
    }
    
    var subtitle: String {
        let remaining = placeComponents.dropFirst()
        guard !remaining.isEmpty else { return "" }
        return remaining.joined(separator: ", ")
    }
    
    var primaryName: String {
        placeName.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? placeName
    }
    
    var countryName: String {
        let components = placeName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return components.last ?? placeName
    }
    
    var countryDisplay: String {
        guard !countryName.isEmpty else { return flagEmoji }
        return flagEmoji.isEmpty ? countryName : "\(flagEmoji) \(countryName)"
    }
    
    private var placeComponents: [String] {
        placeName
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case context
        case properties
        case center
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        placeName = try container.decode(String.self, forKey: .placeName)
        properties = try container.decodeIfPresent(MapboxProperties.self, forKey: .properties)
        center = (try? container.decode([Double].self, forKey: .center)) ?? []
        
        let contexts = try container.decodeIfPresent([MapboxContext].self, forKey: .context) ?? []
        let contextCode = contexts.first(where: { $0.id.hasPrefix("country") })?.shortCode?.uppercased()
        let propertyCode = properties?.shortCode?.uppercased()
        let rawCountryCode = propertyCode ?? contextCode
        countryCode = rawCountryCode?.split(separator: "-").first.map(String.init)
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
