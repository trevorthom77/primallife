//
//  UnsplashService.swift
//  primallife
//
//  Created by Trevor Thompson on 11/17/25.
//

import Foundation

struct UnsplashImageDetails {
    let url: URL
    let photographerName: String?
    let photographerProfileURL: URL?
}

enum UnsplashService {
    private static let accessKey = "REIL_WOXCjSVDsbIkoexE4MVlGNvLW4SU4twImEclXw"
    private static let utmSource = "primallife"
    
    static func fetchImage(for query: String) async -> URL? {
        let details = await fetchImageDetails(for: query)
        return details?.url
    }
    
    static func fetchImageDetails(for query: String) async -> UnsplashImageDetails? {
        var components = URLComponents(string: "https://api.unsplash.com/search/photos")
        let sanitizedQuery = sanitizedQuery(from: query)
        guard !sanitizedQuery.isEmpty else { return nil }
        components?.queryItems = [
            URLQueryItem(name: "query", value: sanitizedQuery)
        ]
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
            
            guard let photo = response.results.first,
                  let url = URL(string: photo.urls.regular)
            else {
                return nil
            }
            
            let profileURL = profileURLWithUTM(from: photo.user?.links.html)
            
            return UnsplashImageDetails(
                url: url,
                photographerName: photo.user?.name,
                photographerProfileURL: profileURL
            )
        } catch {
            return nil
        }
    }
    
    private static func profileURLWithUTM(from base: String?) -> URL? {
        guard let base, var components = URLComponents(string: base) else { return nil }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "utm_source", value: utmSource))
        queryItems.append(URLQueryItem(name: "utm_medium", value: "referral"))
        components.queryItems = queryItems
        return components.url
    }

    private static func sanitizedQuery(from query: String) -> String {
        let filteredScalars = query.unicodeScalars.filter { !$0.properties.isEmoji }
        let cleaned = String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? query.trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }
}

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable {
    let urls: UnsplashPhotoURLs
    let user: UnsplashUser?
    let premium: Bool?
    let plus: Bool?
}

private struct UnsplashPhotoURLs: Decodable {
    let regular: String
}

private struct UnsplashUser: Decodable {
    let name: String?
    let links: UnsplashUserLinks
}

private struct UnsplashUserLinks: Decodable {
    let html: String?
}
