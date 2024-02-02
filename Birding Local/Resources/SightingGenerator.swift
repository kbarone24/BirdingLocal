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
            BirdSighting(speciesCode: "1", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "2", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "3", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "4", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true)
        ]
    }

    var largePlaceholder: [BirdSighting] {
        return [
            BirdSighting(speciesCode: "1", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "2", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "3", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "4", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "5", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "6", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "7", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "8", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "9", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true),
            BirdSighting(speciesCode: "10", commonName: "", scientificName: "", timestamp: "", locationName: "", lat: 0.0, lng: 0.0, howMany: 0, obsValid: true)
        ]
    }

    var mediumDefault: [BirdSighting] {
        return [
            BirdSighting(commonName: "Eastern Bluebird", image: UIImage(named: "EasternBluebird"), speciesCode: "1"),
            BirdSighting(commonName: "Barred Owl", image: UIImage(named: "BarredOwl"), speciesCode: "2"),
            BirdSighting(commonName: "Tufted Titmouse", image: UIImage(named: "TuftedTitmouse"), speciesCode: "3"),
            BirdSighting(commonName: "American Woodcock", image: UIImage(named: "AmericanWoodcock"), speciesCode: "4")
        ]
    }

    var largeDefault: [BirdSighting] {
        return [
            BirdSighting(commonName: "Eastern Bluebird", image: UIImage(named: "EasternBluebird"), speciesCode: "1"),
            BirdSighting(commonName: "Barred Owl", image: UIImage(named: "BarredOwl"), speciesCode: "2"),
            BirdSighting(commonName: "Tufted Titmouse", image: UIImage(named: "TuftedTitmouse"), speciesCode: "3"),
            BirdSighting(commonName: "American Woodcock", image: UIImage(named: "AmericanWoodcock"), speciesCode: "4"),
            BirdSighting(commonName: "Cedar Waxwing", image: UIImage(named: "CedarWaxwing"), speciesCode: "5"),
            BirdSighting(commonName: "Common Raven", image: UIImage(named: "CommonRaven"), speciesCode: "6"),
            BirdSighting(commonName: "Yellow-rumped Warbler", image: UIImage(named: "YellowRumpedWarbler"), speciesCode: "7"),
            BirdSighting(commonName: "Northern Cardinal", image: UIImage(named: "NorthernCardinal"), speciesCode: "8"),
            BirdSighting(commonName: "Yellow-bellied Sapsucker", image: UIImage(named: "YellowBelliedSapsucker"), speciesCode: "10"),
            BirdSighting(commonName: "Cooper's Hawk", image: UIImage(named: "CoopersHawk"), speciesCode: "9")
        ]
    }
}
