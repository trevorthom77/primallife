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
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.supabaseClient) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var viewport: Viewport

    init(coordinate: CLLocationCoordinate2D, locationName: String, countryDisplay: String) {
        self.coordinate = coordinate
        self.locationName = locationName
        self.countryDisplay = countryDisplay
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

                        Button(action: {}) {
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

}
