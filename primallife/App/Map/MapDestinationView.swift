//
//  MapDestinationView.swift
//  primallife
//
//  Created by Trevor Thompson on 1/27/26.
//

import SwiftUI
import CoreLocation
import MapboxMaps

struct MapDestinationView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var viewport: Viewport

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _viewport = State(initialValue: .camera(
            center: coordinate,
            zoom: 7,
            bearing: 0,
            pitch: 0
        ))
    }

    var body: some View {
        Map(viewport: $viewport) {
            MapViewAnnotation(coordinate: coordinate) {
                destinationMarker
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
            .ignoresSafeArea()
    }

    private var destinationMarker: some View {
        Circle()
            .fill(Colors.accent)
            .frame(width: 22, height: 22)
    }
}
