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
        await withUnsafeContinuation { continuation in
            Task(priority: .high) {
                if !widgetFetch {
                    saveToAppGroup(location: location, radius: radius)
                }

                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                var daysBack = 4

                var sightings = await runSightingsFetch(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    maxResults: maxResults,
                    daysBack: daysBack,
                    cachedSightings: cachedSightings
                )

                // go further back in time to fetch enough sightings to fill page
                while sightings.count < min(maxResults, 8), daysBack < 128 {
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

                for i in 0..<sightings.count {
                    let imageInfo = await fetchBirdImageInfo(for: sightings[i], fetchImage: widgetFetch)
                    sightings[i].imageURL = imageInfo.imageURL
                    sightings[i].audioURL = imageInfo.audioURL
                    sightings[i].imageData = imageInfo.imageData
                }
                continuation.resume(returning: sightings)
            }
        }
    }

    private func runSightingsFetch(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Double, maxResults: Int, daysBack: Int, cachedSightings: [BirdSighting]) async -> [BirdSighting] {
        await withUnsafeContinuation { continuation in
            Task {
                let urlString = getURLString(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    maxResults: maxResults,
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

                // cant use end document / start index with EBird API so fetch everything, remove sightings that have already been cached
                var finalSightings = [BirdSighting]()
                if let sightings {
                    for i in 0..<sightings.count {
                        if !cachedSightings.contains(sightings[i]) {
                            finalSightings.append(sightings[i])
                        }
                    }
                }
                continuation.resume(returning: finalSightings)
            }
        }
    }

    private func fetchBirdImageInfo(for birdSighting: BirdSighting, fetchImage: Bool) async -> (imageURL: String?, audioURL: String?, imageData: Data?) {
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
                    URLQueryItem(name: "pithumbsize", value: "\(200)")
                ]

                guard let url = urlComponents?.url else {
                    print("Invalid URL")
                    continuation.resume(returning: (nil, nil, nil))
                    return
                }

                // MARK: Wikimedia API Request
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data, error == nil else {
                        print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                        continuation.resume(returning: (nil, nil, nil))
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
                           let imageURL = thumbnail["source"] as? String {

                            // MARK: Fetch images for widget
                            if fetchImage {
                                self.imageManager.loadImage(with: URL(string: imageURL), progress: nil) { image, data, error, _, _, _ in
                                    let data = data ?? image?.sd_imageData() 
                                    continuation.resume(returning: (imageURL, nil, data))
                                }
                            } else {
                                continuation.resume(returning: (imageURL, nil, nil))
                            }

                        } else {
                            print("Failed to extract image URL from the response.")
                            continuation.resume(returning: (nil, nil, nil ))
                        }
                        //TODO: extract audio file URL

                    } catch {
                        print("Error decoding JSON: \(error)")
                        continuation.resume(returning: (nil, nil, nil))
                    }
                }.resume()
            }
        }
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
        } else {
            print("did not set")
        }

        sharedUserDefaults?.set(location.coordinate.latitude, forKey: "latitude")
        sharedUserDefaults?.set(location.coordinate.longitude, forKey: "longitude")
        sharedUserDefaults?.set(radius, forKey: "radius")
        sharedUserDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
