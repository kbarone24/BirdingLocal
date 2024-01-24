//
//  BirdSighting.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation

struct BirdSighting: Codable {
    // MARK: fetched variables
    var id: String?
    let speciesCode: String
    var commonName: String
    let scientificName: String
    let timestamp: String          // Observation date and time
    let locationName: String?           // Location name where the bird was observed
    let lat: Double                // Latitude of the observation point
    let lng: Double                // Longitude of the observation point
    let howMany: Int?              // Number of birds observed (if specified)
    let obsValid: Bool             // Indicates whether the observation is valid
    // MARK: assigned variables
    var imageURL: String?  // imageURL (fetched from Wikimedia API)
    var audioURL: String?
    var imageData: Data? // only used in widget

    enum CodingKeys: String, CodingKey {
        case id
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

    init(speciesCode: String, commonName: String, scientificNmae: String, timestamp: String, locationName: String?, lat: Double, lng: Double, howMany: Int?, obsValid: Bool, imageURL: String? = nil, audioURL: String? = nil) {
        self.id = UUID().uuidString
        self.speciesCode = speciesCode
        self.commonName = commonName
        self.scientificName = scientificNmae
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
}

extension BirdSighting: Hashable {
    static func == (lhs: BirdSighting, rhs: BirdSighting) -> Bool {
        return lhs.id == rhs.id &&
        lhs.speciesCode == rhs.speciesCode &&
        lhs.timestamp == rhs.timestamp &&
        lhs.lat == rhs.lat &&
        lhs.lng == rhs.lng
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
