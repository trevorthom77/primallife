//
//  MapDestinationView.swift
//  primallife
//
//  Created by Trevor Thompson on 1/27/26.
//

import SwiftUI
import CoreLocation
import MapboxMaps
import Supabase

struct MapDestinationView: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    let countryDisplay: String
    let onFly: (CLLocationCoordinate2D) -> Void
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var viewport: Viewport
    @State private var placeImageURL: URL?
    @State private var photoTask: Task<Void, Never>?
    @State private var nearbyTravelersCount = 0
    @State private var nearbyTravelersTask: Task<Void, Never>?

    private let customPlaceImageNames = [
        "italy",
        "greece",
        "puerto rico",
        "costa rica",
        "australia",
        "jamaica",
        "switzerland"
    ]

    init(
        coordinate: CLLocationCoordinate2D,
        locationName: String,
        countryDisplay: String,
        onFly: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        self.coordinate = coordinate
        self.locationName = locationName
        self.countryDisplay = countryDisplay
        self.onFly = onFly
        let offsetLatitude = min(90, max(-90, coordinate.latitude - 0.7))
        let adjustedCoordinate = CLLocationCoordinate2D(
            latitude: offsetLatitude,
            longitude: coordinate.longitude
        )
        _viewport = State(initialValue: .camera(
            center: adjustedCoordinate,
            zoom: 7,
            bearing: 0,
            pitch: 0
        ))
    }

    var body: some View {
        Map(viewport: $viewport) {
            MapViewAnnotation(coordinate: coordinate) {
                userLocationAnnotation
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
            .overlay(alignment: .bottom) {
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: 32,
                        topTrailing: 32
                    )
                )
                .fill(Colors.card)
                .frame(height: 440)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Colors.secondaryText.opacity(0.12))

                            if let customImageName = customImageName {
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

                        HStack(spacing: -8) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Colors.secondaryText.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }
                            }

                            Circle()
                                .fill(Colors.secondaryText.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text("+\(nearbyTravelersCount)")
                                        .font(.badgeDetail)
                                        .foregroundStyle(Colors.primaryText)
                                }
                                .overlay {
                                    Circle()
                                        .stroke(Colors.card, lineWidth: 3)
                                }
                        }

                        if !locationName.isEmpty {
                            Text(locationName)
                                .font(.travelTitle)
                                .foregroundStyle(Colors.primaryText)
                        }
                        
                        if !countryDisplay.isEmpty {
                            Text(countryDisplay)
                                .font(.travelBody)
                                .foregroundStyle(Colors.secondaryText)
                        }

                        let flyLabel = locationName.isEmpty ? countryDisplay : locationName

                        Button(action: {
                            dismiss()
                            Task { @MainActor in
                                await Task.yield()
                                onFly(coordinate)
                            }
                        }) {
                            Text(flyLabel.isEmpty ? "Fly" : "Fly to \(flyLabel)")
                                .font(.travelBodySemibold)
                                .foregroundStyle(Colors.tertiaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .topLeading) {
                BackButton {
                    dismiss()
                }
                .padding(.leading)
                .padding(.top, 58)
            }
            .onAppear {
                loadImage()
                loadNearbyTravelersCount()
            }
            .onDisappear {
                photoTask?.cancel()
                nearbyTravelersTask?.cancel()
            }
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea()
    }

    private var userLocationAnnotation: some View {
        let outerSize: CGFloat = 66
        let innerSize: CGFloat = 58
        let strokeWidth: CGFloat = 4

        return ZStack {
            Circle()
                .fill(Colors.card)
                .frame(width: outerSize, height: outerSize)

            let avatarURL = profileStore.profile?.avatarURL(using: supabase)

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

    private var imageQuery: String {
        locationName.isEmpty ? countryDisplay : locationName
    }

    private var customImageName: String? {
        let candidates = [locationName, countryDisplay]

        for name in customPlaceImageNames {
            for candidate in candidates where candidate.localizedCaseInsensitiveContains(name) {
                return name
            }
        }

        return nil
    }

    private func loadImage() {
        photoTask?.cancel()
        placeImageURL = nil

        let query = imageQuery
        guard !query.isEmpty else { return }
        guard customImageName == nil else { return }

        photoTask = Task {
            let url = await UnsplashService.fetchImage(for: query)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                placeImageURL = url
            }
        }
    }

    private func loadNearbyTravelersCount() {
        nearbyTravelersTask?.cancel()
        nearbyTravelersCount = 0

        nearbyTravelersTask = Task {
            guard let supabase, let userID = supabase.auth.currentUser?.id else { return }

            let radiusMeters = 60.0 * 1609.344
            let bounds = nearbyBounds(around: coordinate, radius: radiusMeters)
            let originLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            do {
                let rows: [DestinationLocationRow] = try await supabase
                    .from("locations")
                    .select("latitude, longitude")
                    .neq("id", value: userID.uuidString)
                    .gte("latitude", value: bounds.minLatitude)
                    .lte("latitude", value: bounds.maxLatitude)
                    .gte("longitude", value: bounds.minLongitude)
                    .lte("longitude", value: bounds.maxLongitude)
                    .execute()
                    .value

                let count = rows.filter { row in
                    let location = CLLocation(latitude: row.latitude, longitude: row.longitude)
                    return location.distance(from: originLocation) <= radiusMeters
                }.count

                guard !Task.isCancelled else { return }
                await MainActor.run {
                    nearbyTravelersCount = count
                }
            } catch {
                return
            }
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
}

private struct DestinationLocationRow: Decodable {
    let latitude: Double
    let longitude: Double
}
