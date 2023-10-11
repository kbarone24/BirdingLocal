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
        let refresh: PassthroughSubject<Bool, Never>
    }

    struct Output {
        let snapshot: AnyPublisher<Snapshot, Never>
    }

    let ebirdService: EBirdServiceProtocol
    let locationService: LocationServiceProtocol

    var cachedSightings = [BirdSighting]()
    var radius: Double = 10

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

    func bind(to input: Input) -> Output {
        let request = input.refresh
            .receive(on: DispatchQueue.global())
            .flatMap { [unowned self] refresh in
                (self.fetchSightings(refresh: refresh))
            }
            .map { $0 }

        let snapshot = request
            .receive(on: DispatchQueue.main)
            .map { sightings in
                var snapshot = Snapshot()
                snapshot.appendSections([.main])
                _ = sightings.map {
                    snapshot.appendItems([.item(sighting: $0)])
                }
                return snapshot
            }
            .eraseToAnyPublisher()
        return Output(snapshot: snapshot)
    }

    private func fetchSightings(
        refresh: Bool
    ) -> AnyPublisher<([BirdSighting]), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success([]))
                    return
                }

                guard refresh else {
                    promise(.success(self.cachedSightings))
                    return
                }

                Task {
                    let maxResults = self.cachedSightings.isEmpty ? self.initialFetchLimit : self.paginatingFetchLimit

                    let sightings = await self.ebirdService.fetchSightings(
                        for: self.locationService.currentLocation ?? CLLocation(),
                        radius: self.radius,
                        maxResults: maxResults,
                        startIndex: self.cachedSightings.count
                    )
                    promise(.success(sightings))

                    self.cachedSightings = sightings
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
