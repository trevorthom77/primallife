//
//  GlobeMapView.swift
//  primallife
//
//  Created by Trevor Thompson on 1/26/26.
//

import SwiftUI
import MapboxMaps

struct GlobeMapView: View {
    @State private var viewport: Viewport = .styleDefault

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(viewport: $viewport)
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
                .ignoresSafeArea()

            GlobeMapPanel()
                .padding(.horizontal)
                .padding(.bottom, 120)
        }
    }
}

private struct GlobeMapPanel: View {
    var body: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 34)

            Color.clear
                .frame(height: 92)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
