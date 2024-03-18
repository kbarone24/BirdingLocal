//
//  BirdSighting.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import UIKit

struct BirdSighting: Codable {
    // MARK: fetched variables
    var id: String = UUID().uuidString
    let speciesCode: String
    var commonName: String
    let scientificName: String
    let timestamp: String          // Observation date and time
    let locationName: String?      // Location name where the bird was observed
    let lat: Double                // Latitude of the observation point
    let lng: Double                // Longitude of the observation point
    let howMany: Int?              // Number of birds observed (if specified)
    let obsValid: Bool?            // Indicates whether the observation is valid
    // MARK: assigned variables
    var imageURL: String?  // imageURL (fetched from Wikimedia API)
    var audioURL: String?
    var imageData: Data? // only used for rendering widget images

    var visibleTime: String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        if let date = dateFormatter.date(from: timestamp) {
            return formatter.localizedString(for: date, relativeTo: Date()).capitalizingFirstLetter()
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case speciesCode
        case commonName = "comName"
        case scientificName = "sciName"
        case timestamp = "obsDt"
        case locationName
        case lat
        case lng
        case howMany
        case obsValid
    }

    init(speciesCode: String, commonName: String, scientificName: String, timestamp: String, locationName: String?, lat: Double, lng: Double, howMany: Int?, obsValid: Bool, imageURL: String? = nil, audioURL: String? = nil) {
        self.id = UUID().uuidString
        self.speciesCode = speciesCode
        self.commonName = commonName
        self.scientificName = scientificName
        self.timestamp = timestamp
        self.locationName = locationName
        self.lat = lat
        self.lng = lng
        self.howMany = howMany
        self.obsValid = obsValid
        self.imageURL = imageURL
        self.audioURL = audioURL
    }

    init() {
        self.id = UUID().uuidString
        self.speciesCode = ""
        self.commonName = ""
        self.scientificName = ""
        self.timestamp = ""
        self.locationName = ""
        self.lat = 0.0
        self.lng = 0.0
        self.howMany = 0
        self.obsValid = false
        self.imageURL = ""
        self.audioURL = ""
    }

    init(commonName: String, image: UIImage?, speciesCode: String) {
        self.id = UUID().uuidString
        self.speciesCode = speciesCode
        self.commonName = commonName
        self.scientificName = ""
        self.locationName = ""
        self.timestamp = ""
        self.lat = 0
        self.lng = 0
        self.imageData = image?.jpegData(compressionQuality: 1.0) ?? Data()

        self.howMany = 0
        self.obsValid = false
        self.imageURL = ""
        self.audioURL = ""
    }
}

extension BirdSighting: Hashable {
    static func == (lhs: BirdSighting, rhs: BirdSighting) -> Bool {
        lhs.speciesCode == rhs.speciesCode &&
        lhs.timestamp == rhs.timestamp &&
        lhs.lat == rhs.lat &&
        lhs.lng == rhs.lng
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(speciesCode)
        hasher.combine(timestamp)
        hasher.combine(lat)
        hasher.combine(lng)
    }
}

extension BirdSighting {
    func wikiFormattedCommonName() -> String {
        return commonName.prefix(1) + commonName.suffix(commonName.count - 1).lowercased()
    }
}
