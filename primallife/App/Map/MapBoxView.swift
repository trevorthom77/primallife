//
//  MapBoxView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/16/25.
//

import SwiftUI
import Foundation
import Combine
import CoreLocation
import MapboxMaps
import Supabase

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
    @State private var isShowingTribes = false
    @State private var viewport: Viewport = .styleDefault
    @State private var selectedPlace: MapboxPlace?
    @State private var placeImageURL: URL?
    @State private var photoTask: Task<Void, Never>?
    @StateObject private var locationManager = UserLocationManager()
    @State private var userCoordinate: CLLocationCoordinate2D?
    @State private var isUsingSelectedDestination = false
    @State private var hasCenteredOnUser = false
    @State private var airplaneFeedbackToggle = false
    @State private var communityTab: CommunityTab = .tribes
    
    private let profileTribes = [
        ProfileTribe(imageName: "profile4", name: "Pacific Travelers", status: "Active"),
        ProfileTribe(imageName: "profile5", name: "Mountain Crew", status: "Planning")
    ]
    
    private let profileFriends = [
        ProfileFriend(imageName: "profile1", name: "Ava", status: "Online"),
        ProfileFriend(imageName: "profile2", name: "Maya", status: "Planning"),
        ProfileFriend(imageName: "profile3", name: "Liam", status: "Offline")
    ]

    private var userAvatarURL: URL? {
        profileStore.profile?.avatarURL(using: supabase)
    }
    
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(viewport: $viewport) {
                    if let coordinate = userCoordinate {
                        MapViewAnnotation(coordinate: coordinate) {
                            userLocationAnnotation
                        }
                    }
                }
                    .ornamentOptions(
                        OrnamentOptions(
                            scaleBar: ScaleBarViewOptions(
                                position: .topLeading,
                                margins: .zero,
                                visibility: .hidden,
                                useMetricUnits: true
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
                                            
                                            Text("Search")
                                                .font(.travelBody)
                                                .foregroundStyle(Colors.primaryText)
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
                                        .font(.travelTitle)
                                        .foregroundStyle(Colors.tertiaryText)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Colors.accent)
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
                                            zoom: 10,
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
                                                
                                                Text("67+")
                                                    .font(.custom(Fonts.semibold, size: 12))
                                                    .foregroundStyle(Colors.primaryText)
                                            }
                                        }
                                    }
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Colors.secondaryText.opacity(0.12))
                                        
                                        if let imageURL = placeImageURL {
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
                                        handleFly(to: place, camera: proxy.camera)
                                    }) {
                                        Text("Fly")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.tertiaryText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 18)
                                    }
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
                                tab: $communityTab,
                                tribes: profileTribes,
                                friends: profileFriends
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 120)
                        }
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        applySavedDestination(using: proxy.camera)
                        locationManager.requestPermission()
                    }
                    .onReceive(locationManager.$coordinate) { coordinate in
                        guard !isUsingSelectedDestination else { return }
                        userCoordinate = coordinate
                        
                        guard !hasCenteredOnUser, let coordinate else { return }
                        viewport = .camera(
                            center: coordinate,
                            zoom: 10,
                            bearing: 0,
                            pitch: 0
                        )
                        hasCenteredOnUser = true
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
            }
            .navigationDestination(isPresented: $isShowingProfile) {
                profileDestination
            }
            .navigationDestination(isPresented: $isShowingFilters) {
                FiltersView()
            }
            .navigationDestination(isPresented: $isShowingTribes) {
                TribesView()
            }
        }
    }

    @ViewBuilder
    private var avatarButtonImage: some View {
        if let url = profileStore.profile?.avatarURL(using: supabase) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
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
                worldPercent: 0,
                trips: [],
                countries: [],
                tribes: [],
                friends: []
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
        
        photoTask = Task {
            let url = await UnsplashService.fetchImage(for: query)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                placeImageURL = url
            }
        }
    }
    
    private func applyDestinationCoordinate(_ coordinate: CLLocationCoordinate2D) {
        isUsingSelectedDestination = true
        userCoordinate = coordinate
        viewport = .camera(
            center: coordinate,
            zoom: 10,
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
                zoom: 10,
                pitch: 0
            ),
            duration: 0
        )
    }
    
    private func cacheDestinationCoordinate(_ coordinate: CLLocationCoordinate2D) {
        hasSavedDestination = true
        savedDestinationLatitude = coordinate.latitude
        savedDestinationLongitude = coordinate.longitude
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
                zoom: 10,
                pitch: 0
            ),
            duration: 2
        )
        
        Task {
            await updateDestination(to: place.title)
        }
    }
    
    private func updateDestination(to destination: String) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        
        struct DestinationUpdate: Encodable {
            let upcoming_destination: String
        }
        
        do {
            try await supabase
                .from("onboarding")
                .update(DestinationUpdate(upcoming_destination: destination))
                .eq("id", value: userID.uuidString)
                .execute()
            
            await profileStore.loadProfile(for: userID, supabase: supabase)
        } catch {
            print("Failed to update destination: \(error.localizedDescription)")
        }
    }
    
    private var userLocationAnnotation: some View {
        ZStack {
            Circle()
                .fill(Colors.card)
                .frame(width: 60, height: 60)
            
            AsyncImage(url: userAvatarURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Colors.card, lineWidth: 4)
            }
        }
    }
}

private struct MapCommunityPanel: View {
    @Binding var tab: CommunityTab
    let tribes: [ProfileTribe]
    let friends: [ProfileFriend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    ForEach(CommunityTab.allCases, id: \.self) { item in
                        Button {
                            tab = item
                        } label: {
                            Text(item.rawValue)
                                .font(.travelDetail)
                                .foregroundStyle(tab == item ? Colors.tertiaryText : Colors.primaryText)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity)
                                .background(tab == item ? Colors.accent : Colors.secondaryText.opacity(0.18))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 280)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if tab == .tribes {
                        ForEach(tribes) { tribe in
                            tribeCard(tribe)
                        }
                    } else {
                        ForEach(friends) { friend in
                            explorerCard(friend)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 92)
        }
        .padding(16)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.none, value: tab)
    }
    
    private func tribeCard(_ tribe: ProfileTribe) -> some View {
        HStack(spacing: 12) {
            Image(tribe.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(tribe.name)
                    .font(.travelBody)
                    .foregroundStyle(Colors.primaryText)
                
                Text(tribe.status)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
            }
        }
        .frame(width: 220, alignment: .leading)
        .padding(16)
        .background(Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func explorerCard(_ friend: ProfileFriend) -> some View {
        HStack(spacing: 12) {
            Image(friend.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(friend.name)
                    .font(.travelBody)
                    .foregroundStyle(Colors.primaryText)
                
                Text(friend.status)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.accent)
            }
        }
        .frame(width: 220, alignment: .leading)
        .padding(16)
        .background(Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private enum CommunityTab: String, CaseIterable {
    case tribes = "Tribes"
    case travelers = "Travelers"
}

private final class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
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
            break
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
