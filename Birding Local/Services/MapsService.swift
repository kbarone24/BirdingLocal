//
//  OpenStreetMapService.swift
//  Birding Local
//
//  Created by Kenny Barone on 12/27/23.
//

import Foundation
import MapKit

protocol MapsServiceProtocol {
    func fetchCities(searchText: String) async throws -> [SearchResult]
}

class MapsService: NSObject, MapsServiceProtocol {
    private let fetchLimit = 8

    private lazy var completer: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address]
        completer.delegate = self
        return completer
    }()

    private lazy var searchResults = [SearchResult]()
    private lazy var uniqueCities = Set<String>()

    private var cachedSearchText = ""
    private var dispatchGroup: DispatchGroup?

    func fetchCities(searchText: String) async throws -> [SearchResult] {
        await withCheckedContinuation { continuation in
            searchResults.removeAll()
            uniqueCities.removeAll()
            cachedSearchText = searchText

            if completer.isSearching {
                completer.cancel()
            }

            dispatchGroup = DispatchGroup()
            dispatchGroup?.enter()

            dispatchGroup?.notify(queue: .global()) {
                guard searchText == self.cachedSearchText else { return }
                continuation.resume(returning: self.searchResults)
            }

            DispatchQueue.main.async {
                self.completer.queryFragment = searchText
            }
        }
    }
}

extension MapsService: MKLocalSearchCompleterDelegate {
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("search complete failed \(error.localizedDescription)")
        dispatchGroup?.leave()
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        for completerResult in completer.results {
            let title = completerResult.title
            let subtitle = completerResult.subtitle
            let resultTitle = "\(title), \(subtitle)"

            if !uniqueCities.contains(resultTitle) {
                uniqueCities.insert(resultTitle)
                let result = SearchResult(title: title, subtitle: subtitle, completerResult: completerResult)
                searchResults.append(result)
            }
        }
        self.dispatchGroup?.leave()
    }
}
