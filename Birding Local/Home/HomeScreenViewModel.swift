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
        let radius: PassthroughSubject<Double, Never>
        let city: PassthroughSubject<String?, Never>
    }

    struct Output {
        let snapshot: AnyPublisher<Snapshot, Never>
    }

    let ebirdService: EBirdServiceProtocol
    let locationService: LocationServiceProtocol

    var cachedCity: String = ""
    var cachedRadius: Double = 5
    var cachedSightings = [BirdSighting]()

    let initialFetchLimit = 20
    let paginatingFetchLimit = 10

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
        let request = input.radius
            .receive(on: DispatchQueue.global())
            .flatMap { [unowned self] radius in
                (self.fetchSightings(radius: radius))
            }
            .map { $0 }

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { (sightings, radius) in
                var snapshot = Snapshot()
                snapshot.appendSections([.main(radius: radius, city: self.cachedCity)])
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
                    let city = await self.locationService.getCity() ?? ""
                    self.cachedCity = city
                    promise(.success(city))
                }
            }
        }
        .eraseToAnyPublisher()
    }


    private func fetchSightings(
        radius: Double
    ) -> AnyPublisher<(sightings: [BirdSighting], radius: Double), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(([], 0)))
                    return
                }

                Task {
                    let maxResults = self.cachedSightings.isEmpty ? self.initialFetchLimit : self.paginatingFetchLimit

                    let sightings = await self.ebirdService.fetchSightings(
                        for: self.locationService.currentLocation ?? CLLocation(),
                        radius: radius.inKM(),
                        maxResults: maxResults,
                        startIndex: self.cachedSightings.count
                    )
                    promise(.success((sightings, radius)))

                    self.cachedSightings = sightings
                    self.cachedRadius = radius
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
