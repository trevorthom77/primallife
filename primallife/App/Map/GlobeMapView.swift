//
//  GlobeMapView.swift
//  primallife
//
//  Created by Trevor Thompson on 1/26/26.
//

import SwiftUI
import Combine
import CoreLocation
import MapboxMaps
import Supabase
import UIKit

struct GlobeMapView: View {
    @Environment(\.supabaseClient) private var supabase
    @State private var viewport: Viewport = .styleDefault
    @State private var mapTribes: [MapTribeLocation] = []
    @StateObject private var tribeImageStore = TribeImageStore()

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(viewport: $viewport) {
                ForEvery(mapTribes) { tribe in
                    MapViewAnnotation(coordinate: tribe.coordinate) {
                        mapTribeAnnotation(for: tribe)
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
                .task {
                    await fetchMapTribes()
                }
                .ignoresSafeArea()

            GlobeMapPanel()
                .padding(.horizontal)
                .padding(.bottom, 120)
        }
    }

    private func fetchMapTribes() async {
        guard let supabase else { return }

        do {
            let tribes: [MapTribeLocation] = try await supabase
                .from("tribes")
                .select("id, latitude, longitude, photo_url")
                .eq("is_map_tribe", value: true)
                .execute()
                .value

            await MainActor.run {
                mapTribes = tribes
                tribeImageStore.preloadImages(for: tribes)
            }
        } catch {
            print("Failed to fetch map tribes: \(error.localizedDescription)")
        }
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

private struct MapTribeLocation: Identifiable, Decodable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let photoURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case latitude
        case longitude
        case photoURL = "photo_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
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

@MainActor
private final class TribeImageStore: ObservableObject {
    @Published private(set) var images: [URL: Image] = [:]
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
                images[url] = Image(uiImage: uiImage)
            } catch { }
        }
    }
}
