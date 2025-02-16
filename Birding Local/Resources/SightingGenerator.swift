//
//  SightingGenerator.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/1/24.
//

import Foundation
import UIKit

class SightingGenerator {
    var mediumPlaceholder: [BirdSighting] {
        return [
            BirdSighting(speciesCode: "6", commonName: "", scientificName: "", timestamp: "5 hours ago", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "7", commonName: "", scientificName: "", timestamp: "January 10", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
        ]
    }

    var largePlaceholder: [BirdSighting] {
        return [
            BirdSighting(speciesCode: "1", commonName: "", scientificName: "", timestamp: "2 hours ago", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "2", commonName: "", scientificName: "", timestamp: "5 hours ago", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "3", commonName: "", scientificName: "", timestamp: "January 10", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "4", commonName: "", scientificName: "", timestamp: "January 9", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "5", commonName: "", scientificName: "", timestamp: "January 5", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
        ]
    }

    var mediumDefault: [BirdSighting] {
        return [
            BirdSighting(commonName: "Eastern Bluebird", timestamp: "12 minutes ago", image: UIImage(named: "EasternBluebird"), speciesCode: "1"),
            BirdSighting(commonName: "Barred Owl", timestamp: "Yesterday", image: UIImage(named: "BarredOwl"), speciesCode: "2"),
        ]
    }

    var largeDefault: [BirdSighting] {
        return [
            BirdSighting(commonName: "Eastern Bluebird", timestamp: "12 minutes ago", image: UIImage(named: "EasternBluebird"), speciesCode: "1"),
            BirdSighting(commonName: "Barred Owl", timestamp: "45 minutes ago", image: UIImage(named: "BarredOwl"), speciesCode: "2"),
            BirdSighting(commonName: "Tufted Titmouse", timestamp: "3 hours ago", image: UIImage(named: "TuftedTitmouse"), speciesCode: "3"),
            BirdSighting(commonName: "American Woodcock", timestamp: "4 hours ago", image: UIImage(named: "AmericanWoodcock"), speciesCode: "4"),
            BirdSighting(commonName: "Cedar Waxwing", timestamp: "Yesterday", image: UIImage(named: "CedarWaxwing"), speciesCode: "5"),
        ]
    }
}
