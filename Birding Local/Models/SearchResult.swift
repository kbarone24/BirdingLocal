//
//  SearchResult.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/25/23.
//

import Foundation
import CoreLocation
import MapKit

class SearchResult {
    var id: String
    var titleString: String
    var subtitleString: String
    var completerResult: MKLocalSearchCompletion
    var coordinate: CLLocationCoordinate2D?

    var combinedString: String {
        var combined = titleString
        if subtitleString != "" {
            combined += ", \(subtitleString)"
        }
        return combined
    }

    init(title: String, subtitle: String, completerResult: MKLocalSearchCompletion) {
        self.id = UUID().uuidString
        self.titleString = title
        self.subtitleString = subtitle
        self.completerResult = completerResult
    }
}

extension SearchResult: Hashable {
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.titleString == rhs.titleString &&
        lhs.subtitleString == rhs.subtitleString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(titleString)
        hasher.combine(subtitleString)
    }
}
