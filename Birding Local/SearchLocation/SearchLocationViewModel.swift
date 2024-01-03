//
//  SearchLocationViewModel.swift
//  Birding Local
//
//  Created by Kenny Barone on 11/26/23.
//

import Foundation
import Combine
import UIKit

class SearchLocationViewModel {
    typealias Section = SearchLocationController.Section
    typealias Item = SearchLocationController.Item
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    struct Input {
        let searchText: PassthroughSubject<String, Never>
    }

    struct Output {
        let snapshot: AnyPublisher<Snapshot, Never>
    }

    private var cachedResults = [SearchResult]()
    private var cancellables = Set<AnyCancellable>()

    let locationService: LocationServiceProtocol
    let mapsService: MapsServiceProtocol

    init(serviceContainer: ServiceContainer) {
        guard
            let locationService = try? serviceContainer.service(for: \.locationService),
            let mapsService = try? serviceContainer.service(for: \.mapsService)
        else {
            self.locationService = LocationService()
            self.mapsService = MapsService()
            return
        }
        self.locationService = locationService
        self.mapsService = mapsService
    }

    func bind(to input: Input) -> Output {
        let cachedPublisher = input.searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .flatMap { [unowned self] searchText in
                fetchCitiesFromCache(searchText: searchText)
            }

        let databasePublisher = input.searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .flatMap { [unowned self] searchText in
                fetchCitiesFromMaps(searchText: searchText)
            }

        let mergedPublisher = Publishers.CombineLatest(cachedPublisher, databasePublisher)
            .map { (cachedResults, databaseResults) in
                var results = cachedResults
                results.append(contentsOf: databaseResults)
                results = Array(results.removingDuplicates().prefix(6))
                return results
            }

        let snapshot = mergedPublisher
            .receive(on: DispatchQueue.global())
            .map { searchResults in
                var snapshot = Snapshot()
                snapshot.appendSections([.main])
                _ = searchResults.map {
                    snapshot.appendItems([.item(searchResult: $0)], toSection: .main)
                }
                return snapshot
            }
            .eraseToAnyPublisher()

        return Output(snapshot: snapshot)
    }

    private func fetchCitiesFromCache(searchText: String) ->
    AnyPublisher <([SearchResult]), Never> {
        // return any cached results that meet the new searchText criteria
        let filteredResults = cachedResults.filter { $0.combinedString.lowercased().contains(searchText.lowercased()) }
        return Just(filteredResults).eraseToAnyPublisher()
    }

    private func fetchCitiesFromMaps(searchText: String) ->
    AnyPublisher <([SearchResult]), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success([]))
                    return
                }

                Task {
                    let results = try? await self.mapsService.fetchCities(searchText: searchText)
                    self.cachedResults = results ?? []
                    promise(.success(results ?? []))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

