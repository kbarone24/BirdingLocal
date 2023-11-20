//
//  SearchResult.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/25/23.
//

import Foundation

class SearchResult {
    var city: String
    var state: String?
    var country: String?

    init(city: String, state: String? = nil, country: String? = nil) {
        self.city = city
        self.state = state
        self.country = country
    }
}

extension SearchResult: Hashable {
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.city == rhs.city &&
        lhs.state ?? "" == rhs.state ?? "" &&
        lhs.country ?? "" == rhs.country ?? ""
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(city)
        hasher.combine(state)
        hasher.combine(country)
    }
}
