//
//  BirdSighting.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation

struct BirdSighting: Codable {
    let speciesCode: String        // Short code for the bird species
    let comName: String            // Common name of the bird
    let sciName: String            // Scientific name of the bird
    let obsDt: String              // Observation date and time
    let locName: String?           // Location name where the bird was observed
    let lat: Double                // Latitude of the observation point
    let lng: Double                // Longitude of the observation point
    let howMany: Int?              // Number of birds observed (if specified)
    let obsValid: Bool             // Indicates whether the observation is valid
    let locationPrivate: Bool?     // Indicates if the location is private
    let subID: String?             // Submitter's unique identifier (eBird user ID)
    let owner: String?             // Name of the person who submitted the checklist
    let individualCount: Int?      // Count of individual birds (if specified)
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
