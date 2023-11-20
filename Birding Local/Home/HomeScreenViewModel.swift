//
//  HomeScreenViewModel.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import UIKit
import Combine
import IdentifiedCollections
import CoreLocation

class HomeScreenViewModel {
    typealias Section = HomeScreenController.Section
    typealias Item = HomeScreenController.Item
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    struct Input {
        let fetchInput: PassthroughSubject<(radius: Double?, useStartIndex: Bool), Never>
        let city: PassthroughSubject<String?, Never>
    }

    struct Output {
        let snapshot: AnyPublisher<Snapshot, Never>
    }

    let ebirdService: EBirdServiceProtocol
    let locationService: LocationServiceProtocol

    var cachedCity: String?
    var cachedLocation: CLLocation?
    var cachedRadius: Double = 2
    var cachedSightings = [BirdSighting]()

    let initialFetchLimit = 20
    let paginatingFetchLimit = 14

    init(serviceContainer: ServiceContainer) {
        guard let ebirdService = try? serviceContainer.service(for: \.ebirdService),
              let locationService = try? serviceContainer.service(for: \.locationService)
        else {
            ebirdService = EBirdService()
            locationService = LocationService()
            return
        }
        self.ebirdService = ebirdService
        self.locationService = locationService
    }

    func bindForSightings(to input: Input) -> Output {
        let request = input.fetchInput
            .receive(on: DispatchQueue.global())
            .flatMap { [unowned self] fetchInput in
                (self.fetchSightings(radius: fetchInput.radius ?? self.cachedRadius, useStartIndex: fetchInput.useStartIndex))
            }
            .map { $0 }

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { (sightings, radius) in
                var snapshot = Snapshot()
                snapshot.appendSections([.main(radius: radius, city: self.cachedCity ?? "")])
                _ = sightings.map {
                    snapshot.appendItems([.item(sighting: $0)])
                }
                return snapshot
            }
            .eraseToAnyPublisher()
        return Output(snapshot: snapshot)
    }

    func bindForCity(to input: Input) -> Output {
        let request = input.city
            .receive(on: DispatchQueue.global())
            .flatMap { [unowned self] city in
                (self.fetchCity(city: city))
            }
            .map { $0 }

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { city in
                var snapshot = Snapshot()
                snapshot.appendSections([.main(radius: self.cachedRadius, city: city)])
                _ = self.cachedSightings.map {
                    snapshot.appendItems([.item(sighting: $0)])
                }
                return snapshot

            }
            .eraseToAnyPublisher()
        return Output(snapshot: snapshot)
    }

    private func fetchCity(
        city: String?
    ) -> AnyPublisher<(String), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(""))
                    return
                }

                // passed through city
                if let city {
                    self.cachedCity = city
                    promise(.success(city))
                    return
                }

                Task {
                    let locationInfo = await self.locationService.getCity()
                    self.cachedCity = locationInfo.city
                    self.cachedLocation = locationInfo.location
                    promise(.success(city ?? ""))
                }
            }
        }
        .eraseToAnyPublisher()
    }


    private func fetchSightings(
        radius: Double,
        useStartIndex: Bool
    ) -> AnyPublisher<(sightings: [BirdSighting], radius: Double), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(([], 0)))
                    return
                }

                Task {
                    // ebird api doesn't allow for actual pagination so need to fetch everything and remove duplicates
                    let maxResults = self.cachedSightings.isEmpty ? self.initialFetchLimit : self.cachedSightings.count + self.paginatingFetchLimit
                    let cachedSightings = useStartIndex ? self.cachedSightings : []
                    print("max results", maxResults)

                    let sightings = await self.ebirdService.fetchSightings(
                        for: self.locationService.currentLocation ?? CLLocation(),
                        radius: radius.inKM(),
                        maxResults: maxResults,
                        cachedSightings: cachedSightings
                    )
                    // attach to cached sightings on pagination
                    var allSightings = useStartIndex ?
                    (self.cachedSightings + sightings).removingDuplicates() :
                    sightings

                    promise(.success((allSightings, radius)))

                    self.cachedSightings = allSightings
                    self.cachedRadius = radius
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
