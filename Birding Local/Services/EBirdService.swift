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
                var daysBack = 4
                let initialIndex = startIndex

                var sightings = await runSightingsFetch(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    maxResults: maxResults,
                    startIndex: initialIndex,
                    daysBack: daysBack
                )

                // go further back in time to fetch enough sightings to fill page
                while sightings.count < 8, daysBack < 128 {
                    daysBack *= 2

                    let additionalSightings = await runSightingsFetch(
                        latitude: latitude,
                        longitude: longitude,
                        radius: radius,
                        maxResults: maxResults - sightings.count,
                        startIndex: initialIndex + sightings.count,
                        daysBack: daysBack
                    )
                    sightings.append(contentsOf: additionalSightings)
                }

                for i in 0..<sightings.count {
                    let imageInfo = await fetchBirdImageInfo(for: sightings[i])
                    sightings[i].imageURL = imageInfo.imageURL
                    sightings[i].audioURL = imageInfo.audioURL
                }
                continuation.resume(returning: sightings)
            }
        }
    }

    private func runSightingsFetch(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Double, maxResults: Int, startIndex: Int, daysBack: Int) async -> [BirdSighting] {
        await withUnsafeContinuation { continuation in
            Task {
                let urlString = getURLString(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    maxResults: maxResults,
                    startIndex: startIndex,
                    daysBack: daysBack
                )
                guard let url = URL(string: urlString) else {
                    continuation.resume(returning: [])
                    return
                }

                let session = URLSession.shared
                let (data, _) = try await session.data(from: url)

                let decoder = JSONDecoder()
                let sightings = try? decoder.decode([BirdSighting].self, from: data)
                continuation.resume(returning: sightings ?? [])
            }
        }
    }

    private func fetchBirdImageInfo(for birdSighting: BirdSighting) async -> (imageURL: String?, audioURL: String?) {
        await withUnsafeContinuation { continuation in
            Task(priority: .high) {
                // MARK: Wikipedia API URL Construction
                let baseURL = "https://en.wikipedia.org/w/api.php"
                var urlComponents = URLComponents(string: baseURL)
                let commonName = birdSighting.wikiFormattedCommonName()

                urlComponents?.queryItems = [
                    URLQueryItem(name: "action", value: "query"),
                    URLQueryItem(name: "format", value: "json"),
                    URLQueryItem(name: "prop", value: "pageimages"), // images fetches images, revisions fetches the content of the page
                    //    URLQueryItem(name: "rvprop", value: "content"),
                    // ensure URL-encoding for common name value
                    URLQueryItem(name: "titles", value: commonName),
                    URLQueryItem(name: "pithumbsize", value: "\(500)")
                ]

                guard let url = urlComponents?.url else {
                    print("Invalid URL")
                    continuation.resume(returning: (nil, nil))
                    return
                }

                // MARK: Wikimedia API Request
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data, error == nil else {
                        print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                        continuation.resume(returning: (nil, nil))
                        return
                    }

                    do {
                        // Decode jsonString to extract the article's cover image
                        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let query = jsonObject["query"] as? [String: Any],
                           let pages = query["pages"] as? [String: Any],
                           let firstPageID = pages.keys.first,
                           let page = pages[firstPageID] as? [String: Any],
                           let thumbnail = page["thumbnail"] as? [String: Any],
                           let imageUrl = thumbnail["source"] as? String {

                            continuation.resume(returning: (imageUrl, nil))
                        } else {
                            print("Failed to extract image URL from the response.")
                            continuation.resume(returning: (nil, nil))
                        }
                        //TODO: extract audio file URL

                    } catch {
                        print("Error decoding JSON: \(error)")
                        continuation.resume(returning: (nil, nil))
                    }
                }.resume()
            }
        }
    }


    private func getURLString(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Double, maxResults: Int, startIndex: Int, daysBack: Int) -> String {
        let baseURL = "https://api.ebird.org/v2/data/obs/geo/recent"
        return "\(baseURL)?lat=\(latitude)&lng=\(longitude)&maxResults=\(maxResults)&dist=\(radius)&back=\(daysBack)&startIndex=\(startIndex)&key=\(self.apiKey)"
    }
}
