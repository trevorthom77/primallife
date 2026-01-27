//
//  GlobeMapView.swift
//  primallife
//
//  Created by Trevor Thompson on 1/26/26.
//

import SwiftUI
import Foundation
import Combine
import CoreLocation
import MapboxMaps
import Supabase
import UIKit

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

struct GlobeMapView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.supabaseClient) private var supabase
    @State private var viewport: Viewport = .styleDefault
    @State private var mapTribes: [MapTribeLocation] = []
    @State private var mapCenterCoordinate: CLLocationCoordinate2D?
    @State private var locationQueryRadius: CLLocationDistance = 0
    @State private var tribeCountryFlags: [UUID: String] = [:]
    @State private var tribeCreatorsByID: [String: MapTribeCreator] = [:]
    @StateObject private var tribeImageStore = TribeImageStore()
    @State private var isShowingTribes = false
    @State private var isShowingFilters = false
    @State private var tribeFilterCheckInDate: Date?
    @State private var tribeFilterReturnDate: Date?
    @State private var tribeFilterMinAge: Int?
    @State private var tribeFilterMaxAge: Int?
    @State private var tribeFilterGender: String?
    @State private var tribeFilterType: String?
    @State private var tribeFilterInterests: Set<String> = []
    @StateObject private var locationManager = UserLocationManager()
    @State private var userCoordinate: CLLocationCoordinate2D?
    @State private var hasCenteredOnUser = false
    @State private var airplaneFeedbackToggle = false
    @State private var mapCamera: CameraAnimationsManager?
    @State private var locationsRefreshTask: Task<Void, Never>?
    @State private var lastLocationsRefreshCenter: CLLocationCoordinate2D?
    @State private var lastLocationsRefreshRadius: CLLocationDistance = 0
    @State private var lastLocationsRefreshTime: TimeInterval = 0
    @State private var isLoadingLocations = false
    @State private var loadingFeedbackToggle = false
    @State private var suppressLoadingFeedback = true
    private let refreshMovementThresholdFraction: Double = 0.3
    private let refreshRadiusChangeThresholdFraction: Double = 0.3
    private let refreshMinimumInterval: TimeInterval = 0

    private var userAvatarURL: URL? {
        profileStore.profile?.avatarURL(using: supabase)
    }

    private var filteredMapTribes: [MapTribeLocation] {
        let normalizedFilter = tribeFilterType?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        let usesTypeFilter = !normalizedFilter.isEmpty && normalizedFilter != "everyone"
        let minAgeFilter = tribeFilterMinAge
        let maxAgeFilter = tribeFilterMaxAge
        let isAgeFilterActive = minAgeFilter != nil || maxAgeFilter != nil
        let interestsFilter = tribeFilterInterests

        guard usesTypeFilter || isAgeFilterActive || !interestsFilter.isEmpty else { return mapTribes }

        return mapTribes.filter { tribe in
            let matchesType: Bool = {
                guard usesTypeFilter else { return true }
                let tribeGender = tribe.gender?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() ?? ""
                if normalizedFilter.contains("girl") {
                    return tribeGender.contains("girl")
                }
                if normalizedFilter.contains("boy") {
                    return tribeGender.contains("boy")
                }
                return true
            }()

            let matchesAge: Bool = {
                guard isAgeFilterActive else { return true }
                guard let minAge = tribe.minAge, let maxAge = tribe.maxAge else { return true }
                if let minAgeFilter, maxAge < minAgeFilter { return false }
                if let maxAgeFilter, minAge > maxAgeFilter { return false }
                return true
            }()

            let matchesInterests: Bool = {
                guard !interestsFilter.isEmpty else { return true }
                return tribe.interests.contains { interestsFilter.contains($0) }
            }()

            return matchesType && matchesAge && matchesInterests
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MapReader { proxy in
                    Map(viewport: $viewport) {
                        if let coordinate = userCoordinate {
                            MapViewAnnotation(coordinate: coordinate) {
                                userLocationAnnotation
                            }
                            .priority(1)
                        }

                        ForEvery(filteredMapTribes) { tribe in
                            MapViewAnnotation(coordinate: tribe.coordinate) {
                                let flag = tribeCountryFlags[tribe.id] ?? ""
                                let creator = tribeCreatorsByID[tribe.ownerID.uuidString.lowercased()]
                                NavigationLink {
                                    TribesSocialView(
                                        imageURL: tribe.photoURL,
                                        title: tribe.name,
                                        location: tribe.destination,
                                        flag: flag,
                                        endDate: tribe.endDate,
                                        minAge: tribe.minAge,
                                        maxAge: tribe.maxAge,
                                        createdAt: tribe.createdAt,
                                        gender: tribe.gender,
                                        aboutText: tribe.description,
                                        interests: tribe.interests,
                                        placeName: tribe.destination,
                                        tribeID: tribe.id,
                                        createdBy: creator?.fullName,
                                        createdByAvatarPath: creator?.avatarPath,
                                        isCreator: supabase?.auth.currentUser?.id == tribe.ownerID
                                    )
                                } label: {
                                    mapTribeAnnotation(for: tribe)
                                }
                                .buttonStyle(.plain)
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
                    .onMapIdle { _ in
                        guard let map = proxy.map else { return }
                        updateSearchArea(using: map)
                        guard let center = mapCenterCoordinate else { return }
                        let radius = locationQueryRadius
                        guard radius > 0 else { return }
                        guard shouldRefreshLocations(for: center, radius: radius) else { return }
                        refreshLocations()
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: loadingFeedbackToggle)
                    .onAppear {
                        mapCamera = proxy.camera
                        locationManager.requestPermission()
                        suppressLoadingFeedback = true
                    }
                    .onReceive(locationManager.$coordinate) { coordinate in
                        userCoordinate = coordinate
                        guard !hasCenteredOnUser, let coordinate else { return }
                        viewport = .camera(
                            center: coordinate,
                            zoom: 8,
                            bearing: 0,
                            pitch: 0
                        )
                        hasCenteredOnUser = true
                    }
                    .task {
                        refreshLocations()
                    }
                    .overlay(alignment: .topLeading) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(Colors.secondaryText)

                                    Text("🇦🇺")
                                        .font(.travelBody)
                                        .foregroundStyle(Colors.primaryText)
                                        .lineLimit(1)

                                    Text("Sydney, Australia")
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
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 12) {
                                Button(action: {
                                    airplaneFeedbackToggle.toggle()
                                    guard let coordinate = userCoordinate, let camera = mapCamera else { return }
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

                                Button(action: {
                                    isShowingTribes = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Colors.accent)
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "plus")
                                            .foregroundStyle(Colors.tertiaryText)
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 58)
                    }
                    .overlay(alignment: .top) {
                        if isLoadingLocations {
                            loadingIndicator
                                .padding(.top, 120)
                                .padding(.horizontal)
                        }
                    }
                    .ignoresSafeArea()
                    .onDisappear {
                        stopLocationsRefresh()
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                GlobeMapPanel(
                    tribes: filteredMapTribes,
                    tribeFlags: tribeCountryFlags,
                    tribeCreators: tribeCreatorsByID,
                    tribeImageStore: tribeImageStore
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 120)
        }
        .ignoresSafeArea()
        .navigationDestination(isPresented: $isShowingTribes) {
            MapTribeView(isShowingTribes: $isShowingTribes)
        }
        .navigationDestination(isPresented: $isShowingFilters) {
            UpcomingTripsFilterView(
                filterCheckInDate: $tribeFilterCheckInDate,
                filterReturnDate: $tribeFilterReturnDate,
                filterMinAge: $tribeFilterMinAge,
                filterMaxAge: $tribeFilterMaxAge,
                filterGender: $tribeFilterGender,
                filterOriginID: .constant(nil),
                filterTribeType: $tribeFilterType,
                filterTravelDescription: .constant(nil),
                filterInterests: $tribeFilterInterests,
                showsTribeFilters: true
            )
        }
    }
    }

    private func fetchMapTribes() async {
        guard let supabase else { return }
        guard let coordinate = mapCenterCoordinate else { return }
        let radius = locationQueryRadius
        guard radius > 0 else { return }

        let bounds = nearbyBounds(around: coordinate, radius: radius)
        let originLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let tribes: [MapTribeLocation] = try await supabase
                .from("tribes")
                .select("id, owner_id, name, destination, description, end_date, min_age, max_age, created_at, gender, interests, photo_url, latitude, longitude")
                .eq("is_map_tribe", value: true)
                .gte("latitude", value: bounds.minLatitude)
                .lte("latitude", value: bounds.maxLatitude)
                .gte("longitude", value: bounds.minLongitude)
                .lte("longitude", value: bounds.maxLongitude)
                .execute()
                .value

            let nearbyTribes = tribes.filter { tribe in
                let location = CLLocation(latitude: tribe.latitude, longitude: tribe.longitude)
                return location.distance(from: originLocation) <= radius
            }

            await MainActor.run {
                mapTribes = nearbyTribes
                tribeImageStore.preloadImages(for: nearbyTribes)
            }
            let ownerIDs = Array(Set(nearbyTribes.map(\.ownerID)))
            await loadMapTribeCreators(for: ownerIDs)
            await updateTribeCountryFlags(for: nearbyTribes)
        } catch {
            print("Failed to fetch map tribes: \(error.localizedDescription)")
        }
    }

    private func loadMapTribeCreators(for userIDs: [UUID]) async {
        guard let supabase else { return }
        guard !userIDs.isEmpty else { return }

        let normalizedIDs = Set(userIDs.map { $0.uuidString.lowercased() })
        let missingIDs = await MainActor.run {
            normalizedIDs.filter { tribeCreatorsByID[$0] == nil }
        }
        guard !missingIDs.isEmpty else { return }

        do {
            let creators: [MapTribeCreator] = try await supabase
                .from("onboarding")
                .select("id, full_name, avatar_url")
                .in("id", values: Array(missingIDs))
                .execute()
                .value

            let lookup = Dictionary(uniqueKeysWithValues: creators.map { ($0.id.lowercased(), $0) })
            await MainActor.run {
                tribeCreatorsByID.merge(lookup) { _, new in new }
            }
        } catch {
            return
        }
    }

    private func updateTribeCountryFlags(for tribes: [MapTribeLocation]) async {
        let missingTribes = await MainActor.run {
            tribes.filter { tribeCountryFlags[$0.id] == nil }
        }
        guard !missingTribes.isEmpty else { return }

        for tribe in missingTribes {
            let flag = await fetchCountryFlag(for: tribe.coordinate)
            guard !flag.isEmpty else { continue }
            await MainActor.run {
                tribeCountryFlags[tribe.id] = flag
            }
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

    private func updateSearchArea(using map: MapboxMap) {
        let cameraState = map.cameraState
        let cameraOptions = CameraOptions(cameraState: cameraState)
        let bounds = map.coordinateBounds(for: cameraOptions)
        guard !bounds.isEmpty else { return }
        let center = cameraState.center
        let radius = visibleRadius(for: center, in: bounds)
        guard radius > 0 else { return }
        mapCenterCoordinate = center
        locationQueryRadius = radius
    }

    private func visibleRadius(for center: CLLocationCoordinate2D, in bounds: CoordinateBounds) -> CLLocationDistance {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let northLocation = CLLocation(latitude: bounds.north, longitude: center.longitude)
        let southLocation = CLLocation(latitude: bounds.south, longitude: center.longitude)
        let eastLocation = CLLocation(latitude: center.latitude, longitude: bounds.east)
        let westLocation = CLLocation(latitude: center.latitude, longitude: bounds.west)
        let verticalRadius = min(centerLocation.distance(from: northLocation), centerLocation.distance(from: southLocation))
        let horizontalRadius = min(centerLocation.distance(from: eastLocation), centerLocation.distance(from: westLocation))
        return min(verticalRadius, horizontalRadius)
    }

    private func shouldRefreshLocations(for center: CLLocationCoordinate2D, radius: CLLocationDistance) -> Bool {
        let now = Date().timeIntervalSinceReferenceDate
        if now - lastLocationsRefreshTime < refreshMinimumInterval {
            return false
        }
        guard let lastCenter = lastLocationsRefreshCenter, lastLocationsRefreshRadius > 0 else {
            return true
        }
        let lastRadius = lastLocationsRefreshRadius
        let lastLocation = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
        let currentLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = currentLocation.distance(from: lastLocation)
        let moveThreshold = radius * refreshMovementThresholdFraction
        let radiusThreshold = lastRadius * refreshRadiusChangeThresholdFraction
        return distance >= moveThreshold || abs(radius - lastRadius) >= radiusThreshold
    }

    private func refreshLocations() {
        locationsRefreshTask?.cancel()
        guard let center = mapCenterCoordinate, locationQueryRadius > 0 else {
            isLoadingLocations = false
            return
        }
        lastLocationsRefreshCenter = center
        lastLocationsRefreshRadius = locationQueryRadius
        lastLocationsRefreshTime = Date().timeIntervalSinceReferenceDate
        if !suppressLoadingFeedback {
            isLoadingLocations = true
            loadingFeedbackToggle.toggle()
        }
        locationsRefreshTask = Task {
            await fetchMapTribes()
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

    private func mapTribeAnnotation(for tribe: MapTribeLocation) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Colors.card)
                .frame(width: 66, height: 66)

            Group {
                if let photoURL = tribe.photoURL {
                    if let cachedImage = tribeImageStore.image(for: photoURL) {
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
            .task(id: tribe.photoURL) {
                if let photoURL = tribe.photoURL {
                    tribeImageStore.loadImage(for: photoURL)
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Colors.card, lineWidth: 4)
            }
        }
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

private struct GlobeMapPanel: View {
    @Environment(\.supabaseClient) private var supabase
    let tribes: [MapTribeLocation]
    let tribeFlags: [UUID: String]
    let tribeCreators: [String: MapTribeCreator]
    @ObservedObject var tribeImageStore: TribeImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if tribes.isEmpty {
                HStack {
                    Spacer()
                    Text("No tribes nearby yet.")
                        .font(.travelBody)
                        .foregroundStyle(Colors.secondaryText)
                    Spacer()
                }
                .frame(height: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tribes) { tribe in
                            let flag = tribeFlags[tribe.id] ?? ""
                            let creator = tribeCreators[tribe.ownerID.uuidString.lowercased()]
                            NavigationLink {
                                TribesSocialView(
                                    imageURL: tribe.photoURL,
                                    title: tribe.name,
                                    location: tribe.destination,
                                    flag: flag,
                                    endDate: tribe.endDate,
                                    minAge: tribe.minAge,
                                    maxAge: tribe.maxAge,
                                    createdAt: tribe.createdAt,
                                    gender: tribe.gender,
                                    aboutText: tribe.description,
                                    interests: tribe.interests,
                                    placeName: tribe.destination,
                                    tribeID: tribe.id,
                                    createdBy: creator?.fullName,
                                    createdByAvatarPath: creator?.avatarPath,
                                    isCreator: supabase?.auth.currentUser?.id == tribe.ownerID
                                )
                            } label: {
                                tribeCard(tribe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(height: 180)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func tribeCard(_ tribe: MapTribeLocation) -> some View {
        let flag = tribeFlags[tribe.id] ?? ""
        let destination = flag.isEmpty ? tribe.destination : "\(flag) \(tribe.destination)"

        return VStack(alignment: .leading, spacing: 8) {
            tribeImage(for: tribe)
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Colors.card, lineWidth: 4)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(tribe.name)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(destination)
                    .font(.tripsfont)
                    .foregroundStyle(Colors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(width: 200, alignment: .leading)
        .padding(10)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func tribeImage(for tribe: MapTribeLocation) -> some View {
        if let photoURL = tribe.photoURL {
            Group {
                if let cachedImage = tribeImageStore.image(for: photoURL) {
                    cachedImage
                        .resizable()
                        .scaledToFill()
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
            .task(id: photoURL) {
                tribeImageStore.loadImage(for: photoURL)
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }
}

private struct MapTribeLocation: Identifiable, Decodable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let destination: String
    let description: String?
    let endDate: Date
    let minAge: Int?
    let maxAge: Int?
    let createdAt: Date
    let gender: String?
    let interests: [String]
    let latitude: Double
    let longitude: Double
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case destination
        case description
        case endDate = "end_date"
        case minAge = "min_age"
        case maxAge = "max_age"
        case createdAt = "created_at"
        case gender
        case interests
        case latitude
        case longitude
        case photoURL = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decode(UUID.self, forKey: .ownerID)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        destination = try container.decodeIfPresent(String.self, forKey: .destination) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)

        let endDateString = try container.decode(String.self, forKey: .endDate)
        guard let decodedEndDate = mapTripsDateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.endDate], debugDescription: "Invalid end date format")
            )
        }
        endDate = decodedEndDate

        minAge = try container.decodeIfPresent(Int.self, forKey: .minAge)
        maxAge = try container.decodeIfPresent(Int.self, forKey: .maxAge)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let decodedCreatedAt = mapTripsTimestampFormatterWithFractional.date(from: createdAtString)
            ?? mapTripsTimestampFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.createdAt], debugDescription: "Invalid created at format")
            )
        }
        createdAt = decodedCreatedAt

        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        if let photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURL) {
            photoURL = URL(string: photoURLString)
        } else {
            photoURL = nil
        }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct MapTribeCreator: Decodable {
    let id: String
    let fullName: String
    let avatarPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarPath = "avatar_url"
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

    var flagEmoji: String {
        guard let countryCode else { return "" }
        return countryCode.flagEmoji
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

private enum MapTribeImageCache {
    static var images: [URL: Image] = [:]
}

@MainActor
private final class TribeImageStore: ObservableObject {
    @Published private(set) var images: [URL: Image] = MapTribeImageCache.images
    private var inFlight: Set<URL> = []

    func image(for url: URL) -> Image? {
        images[url]
    }

    func preloadImages(for tribes: [MapTribeLocation]) {
        for tribe in tribes {
            if let url = tribe.photoURL {
                loadImage(for: url)
            }
        }
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
                MapTribeImageCache.images[url] = image
            } catch { }
        }
    }
}
