//
//  HomeScreenViewModel.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import UIKit
import Combine
import CoreLocation

class HomeScreenViewModel {
    typealias Section = HomeScreenController.Section
    typealias Item = HomeScreenController.Item
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    struct Input {
        let refresh: PassthroughSubject<Bool, Never>
        let fetchInput: PassthroughSubject<(currentLocation: CLLocation?, radius: Double?, useStartIndex: Bool), Never>
        let city: PassthroughSubject<(passedLocation: CLLocation?, radius: Double?), Never>
    }

    struct Output {
        let snapshot: AnyPublisher<Snapshot, Never>
    }

    let ebirdService: EBirdServiceProtocol
    let locationService: LocationServiceProtocol

    var cachedCity: String?
    var cachedLocation: CLLocation?
    var cachedRadius: Double = 1
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

    func bindForCachedSightings(to input: Input) -> Output {
        // just return cached sightings (usually an empty array)
        let request = input.refresh
            .map { _ in
                return self.getCachedSightings()
            }
            .switchToLatest()

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { (sightings) in
                var snapshot = Snapshot()
                guard !sightings.isEmpty else { return snapshot }
                
                snapshot.appendSections([.main(radius: self.cachedRadius, city: self.cachedCity ?? "")])
                _ = sightings.map {
                    snapshot.appendItems([.item(sighting: $0)])
                }
                return snapshot
            }
            .eraseToAnyPublisher()

        return Output(snapshot: snapshot)
    }


    func bindForSightings(to input: Input) -> Output {
        let request = input.fetchInput
            .receive(on: DispatchQueue.global())
            .flatMap { [unowned self] sightingsPublisher in
                (self.fetchSightings(
                    currentLocation: sightingsPublisher.currentLocation,
                    radius: sightingsPublisher.radius ?? self.cachedRadius,
                    useStartIndex: sightingsPublisher.useStartIndex
                ))
            }
            .map { $0 }

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { (sightings) in
                var snapshot = Snapshot()
                guard !sightings.isEmpty else { return snapshot }

                snapshot.appendSections([.main(radius: self.cachedRadius, city: self.cachedCity ?? "")])
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
            .flatMap { [unowned self] cityInput in
                (self.fetchCity(passedLocation: cityInput.passedLocation, radius: cityInput.radius ?? self.cachedRadius))
            }
            .map { $0 }

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { (city, radius) in
                var snapshot = Snapshot()
                let city = city.isEmpty ? "Current location unavailable  " : city
                snapshot.appendSections([.main(radius: radius, city: city)])
                _ = self.cachedSightings.map {
                    snapshot.appendItems([.item(sighting: $0)])
                }
                return snapshot

            }
            .eraseToAnyPublisher()
        return Output(snapshot: snapshot)
    }

    private func fetchCity(
        passedLocation: CLLocation?,
        radius: Double
    ) -> AnyPublisher<(city: String, radius: Double), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(("", 0)))
                    return
                }

                Task {
                    let locationInfo = await self.locationService.getCity(passedLocation: passedLocation)
                    promise(.success((city: locationInfo.city ?? "", radius: radius)))

                    self.cachedCity = locationInfo.city
                    self.cachedLocation = locationInfo.location
                    self.cachedRadius = radius
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func getCachedSightings() -> AnyPublisher<([BirdSighting]), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(([])))
                    return
                }

                promise(.success((cachedSightings)))
            }
        }
        .eraseToAnyPublisher()
    }

    private func fetchSightings(
        currentLocation: CLLocation?,
        radius: Double,
        useStartIndex: Bool
    ) -> AnyPublisher<([BirdSighting]), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(([])))
                    return
                }

                Task {
                    // ebird api doesn't allow for actual pagination so need to fetch everything and remove duplicates
                    let maxResults = self.cachedSightings.isEmpty ? self.initialFetchLimit : self.cachedSightings.count + self.paginatingFetchLimit
                    let cachedSightings = useStartIndex ? self.cachedSightings : []

                    // use passed location if available, else user's currentLocation
                    let sightings = await self.ebirdService.fetchSightings(
                        for: currentLocation ?? self.locationService.currentLocation ?? CLLocation(),
                        radius: radius.inKM(),
                        maxResults: maxResults,
                        cachedSightings: cachedSightings,
                        widgetFetch: false
                    )
                    // attach to cached sightings on pagination

                    let allSightings = useStartIndex ?
                    (self.cachedSightings + sightings).removingDuplicates() :
                    sightings

                    promise(.success((allSightings)))

                    self.cachedSightings = allSightings
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
