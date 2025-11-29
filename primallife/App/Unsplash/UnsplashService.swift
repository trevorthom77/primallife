//
//  UnsplashService.swift
//  primallife
//
//  Created by Trevor Thompson on 11/17/25.
//

import Foundation

enum UnsplashService {
    private static let accessKey = "REIL_WOXCjSVDsbIkoexE4MVlGNvLW4SU4twImEclXw"
    
    static func fetchImage(for query: String) async -> URL? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.unsplash.com/search/photos?query=\(encodedQuery)&per_page=1&orientation=landscape")
        else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
            guard let urlString = response.results.first?.urls.regular else { return nil }
            return URL(string: urlString)
        } catch {
            return nil
        }
    }
}

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable {
    let urls: UnsplashPhotoURLs
}

private struct UnsplashPhotoURLs: Decodable {
    let regular: String
}
