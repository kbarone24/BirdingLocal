//
//  EBirdAPIFetch.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import CoreLocation

protocol EBirdServiceProtocol {
    func fetchSightings(for location: CLLocation, radius: Double, maxResults: Int, startIndex: Int) async -> [BirdSighting]
}

final class EBirdService: EBirdServiceProtocol {
    private let apiKey = "reta932vajr1"

    func fetchSightings(for location: CLLocation, radius: Double, maxResults: Int, startIndex: Int) async -> [BirdSighting] {
        await withUnsafeContinuation { continuation in
            Task(priority: .high) {
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                let urlString = getURLString(latitude: latitude, longitude: longitude, radius: radius, maxResults: maxResults, startIndex: startIndex)
                guard let url = URL(string: urlString) else {
                    print("invalid URL")
                    continuation.resume(returning: [])
                    return
                }

                let session = URLSession.shared
                let (data, _) = try await session.data(from: url)

                let decoder = JSONDecoder()
                let sightings = try decoder.decode([BirdSighting].self, from: data)
                continuation.resume(returning: sightings)
            }
        }
    }


    private func getURLString(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Double, maxResults: Int, startIndex: Int) -> String {
        let baseURL = "https://api.ebird.org/v2/data/obs/geo/recent"
        let daysBack = 7
        return "\(baseURL)?lat=\(latitude)&lng=\(longitude)&maxResults=\(maxResults)&dist=\(radius)&back=\(daysBack)&startIndex=\(startIndex)&key=\(self.apiKey)"
    }
}
