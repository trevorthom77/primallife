//
//  AnimalSpottingView.swift
//  primallife
//
//  Created by Trevor Thompson on 11/24/25.
//

import SwiftUI
import MapboxMaps

struct AnimalSpottingView: View {
    @State private var viewport: Viewport = .styleDefault

    var body: some View {
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
                        margins: .zero,
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
            .overlay(alignment: .topTrailing) {
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Colors.accent)
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus")
                            .foregroundStyle(Colors.tertiaryText)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.top, 60)
            }
            .ignoresSafeArea()
    }
}

#Preview {
    AnimalSpottingView()
}
