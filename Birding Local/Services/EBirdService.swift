//
//  EBirdAPIFetch.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import CoreLocation
import SDWebImage
import WidgetKit

protocol EBirdServiceProtocol {
    func fetchSightings(for location: CLLocation, radius: Double, maxResults: Int, cachedSightings: [BirdSighting], widgetFetch: Bool) async -> [BirdSighting]
}

final class EBirdService: EBirdServiceProtocol {
    let imageManager = SDWebImageManager()

    func fetchSightings(for location: CLLocation, radius: Double, maxResults: Int, cachedSightings: [BirdSighting], widgetFetch: Bool) async -> [BirdSighting] {
        // TODO: separate fetches for widget and main app
        if !widgetFetch {
            saveToAppGroup(location: location, radius: radius)
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        var daysBack = 30

        var sightings = await runSightingsFetch(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            maxResults: maxResults,
            daysBack: daysBack,
            cachedSightings: cachedSightings
        )

        // Go further back in time to fetch enough sightings to fill the page
        while sightings.count < min(maxResults, 8), daysBack < 200 {
            daysBack *= 2

            let additionalSightings = await runSightingsFetch(
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                maxResults: maxResults,
                daysBack: daysBack,
                cachedSightings: cachedSightings
            )
            sightings.append(contentsOf: additionalSightings)
        }

        // Fetch bird image info
        var updatedSightings: [BirdSighting] = []
        // Use TaskGroup for parallelized fetching
        await withTaskGroup(of: BirdSighting?.self) { group in
            for sighting in sightings {
                group.addTask {
                    let imageURL = await self.fetchBirdImageInfo(for: sighting, fetchImage: widgetFetch)

                    var updatedSighting = sighting
                    updatedSighting.imageURL = imageURL
                    if widgetFetch, let imageURL {
                        updatedSighting.imageData = try? await self.fetchImageData(urlString: imageURL)
                    }
                    return updatedSighting
                }
            }

        for await result in group {
              if let sighting = result {
                  updatedSightings.append(sighting)
              }
          }
        }

        return updatedSightings.sorted(by: { $0.timestamp > $1.timestamp })
    }


    private func runSightingsFetch(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Double, maxResults: Int, daysBack: Int, cachedSightings: [BirdSighting]) async -> [BirdSighting] {
        let urlString = getURLString(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            maxResults: maxResults,
            daysBack: daysBack
        )
        guard let url = URL(string: urlString) else {
            print("Invalid URL string")
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let sightings = try decoder.decode([BirdSighting].self, from: data)

            // Remove sightings that have already been cached
            let finalSightings = sightings.filter { !cachedSightings.contains($0) }
            return finalSightings
        } catch {
            print("Error fetching or decoding data: \(error)")
            return []
        }
    }
    private func fetchBirdImageInfo(for birdSighting: BirdSighting, fetchImage: Bool) async -> String? {
        let baseURL = "https://en.wikipedia.org/w/api.php"
        var urlComponents = URLComponents(string: baseURL)
        let commonName = birdSighting.wikiFormattedCommonName()

        urlComponents?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "prop", value: "pageimages"),
            URLQueryItem(name: "titles", value: commonName),
            URLQueryItem(name: "pithumbsize", value: "200")
        ]

        guard let url = urlComponents?.url else {
            print("Invalid URL")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let query = jsonObject["query"] as? [String: Any],
               let pages = query["pages"] as? [String: Any],
               let page = pages.values.first as? [String: Any],
               let thumbnail = page["thumbnail"] as? [String: Any],
               let imageURL = thumbnail["source"] as? String {

                return imageURL
            } else {
                print("Failed to extract image URL from the response.")
                return nil
            }
        } catch {
            print("Error fetching data or decoding JSON: \(error)")
            return nil
        }
    }

    private func fetchImageData(urlString: String) async throws -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    private func getURLString(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Double, maxResults: Int, daysBack: Int) -> String {
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        guard let keys, let apiKey = keys["eBirdAPIKey"] as? String, apiKey != "" else {
            return ""
        }

        let baseURL = "https://api.ebird.org/v2/data/obs/geo/recent"
        return "\(baseURL)?lat=\(latitude)&lng=\(longitude)&maxResults=\(maxResults)&dist=\(radius)&back=\(daysBack)&key=\(apiKey)"
    }

    private func saveToAppGroup(location: CLLocation, radius: Double) {
        // save recent location/radius data to App Group for use in widget
        guard !(location.coordinate.latitude == 0 && location.coordinate.longitude == 0) else {
            return
        }

        // check to see if user has updated user defaults before
        let sharedUserDefaults = UserDefaults(suiteName: AppGroupNames.defaultGroup.rawValue)
        let latitude = sharedUserDefaults?.object(forKey: "latitude") as? Double ?? 0
        let longitude = sharedUserDefaults?.object(forKey: "longitude") as? Double ?? 0
        if latitude == 0 && longitude == 0 {
            // user defaults set for first time
            NotificationCenter.default.post(name: Notification.Name(NotificationNames.SetLocationForFirstTime.rawValue), object: nil)
        }

        sharedUserDefaults?.set(location.coordinate.latitude, forKey: "latitude")
        sharedUserDefaults?.set(location.coordinate.longitude, forKey: "longitude")
        sharedUserDefaults?.set(radius, forKey: "radius")
        sharedUserDefaults?.synchronize()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
