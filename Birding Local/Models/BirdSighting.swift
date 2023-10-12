//
//  BirdSighting.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation

struct BirdSighting: Codable {
    // MARK: fetched variables
    let speciesCode: String
    var comName: String
    let sciName: String
    let obsDt: String              // Observation date and time
    let locName: String?           // Location name where the bird was observed
    let lat: Double                // Latitude of the observation point
    let lng: Double                // Longitude of the observation point
    let howMany: Int?              // Number of birds observed (if specified)
    let obsValid: Bool             // Indicates whether the observation is valid
    // MARK: assigned variables
    var imageURL: String?  // imageURL (fetched from Wikimedia API)
    var audioURL: String?
}

extension BirdSighting: Hashable {
    static func == (lhs: BirdSighting, rhs: BirdSighting) -> Bool {
        return lhs.speciesCode == rhs.speciesCode &&
        lhs.obsDt == rhs.obsDt &&
        lhs.lat == rhs.lat &&
        lhs.lng == rhs.lng
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(speciesCode)
        hasher.combine(obsDt)
        hasher.combine(lat)
        hasher.combine(lng)
    }
}

extension BirdSighting {
    func wikiFormattedCommonName() -> String {
        return comName.prefix(1) + comName.suffix(comName.count - 1).lowercased()
    }
}
