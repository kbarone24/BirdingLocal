//
//  LocationEditorViewModel.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/25/23.
//

import Foundation
import Combine
import UIKit
import CoreLocation

class LocationEditorViewModel {
    typealias Section = LocationEditorController.Section
    typealias Item = LocationEditorController.Item
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    struct Input {
        let searchText: PassthroughSubject<String, Never>
    }

    struct Output {
        let snapshot: AnyPublisher<Snapshot, Never>
    }
    private var cancellables = Set<AnyCancellable>()

    let locationService: LocationServiceProtocol
    var currentLocation: CLLocation
    var city: String
    var radius: Double

    init(serviceContainer: ServiceContainer, currentLocation: CLLocation, city: String, radius: Double) {
        self.currentLocation = currentLocation
        self.city = city
        self.radius = radius

        guard let locationService = try? serviceContainer.service(for: \.locationService)
        else {
            self.locationService = LocationService()
            return
        }
        self.locationService = locationService
    }
}
