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
    struct Input {
        let location: PassthroughSubject<CLLocation, Never>
        let city: PassthroughSubject<String, Never>
        let radius: PassthroughSubject<Double, Never>
    }

    struct Output {
        let location: AnyPublisher<CLLocation, Never>
        let city: AnyPublisher<String, Never>
        let radius: AnyPublisher<Double, Never>
    }

    let locationService: LocationServiceProtocol
    var cachedLocation: CLLocation
    var cachedCity: String
    var cachedRadius: Double

    init(serviceContainer: ServiceContainer, currentLocation: CLLocation, city: String, radius: Double) {
        self.cachedLocation = currentLocation
        self.cachedCity = city
        self.cachedRadius = radius

        guard let locationService = try? serviceContainer.service(for: \.locationService)
        else {
            self.locationService = LocationService()
            return
        }
        self.locationService = locationService
    }

    func bind(to input: Input) -> Output {
        let locationPublisher = input.location
            .map { location in
                self.cachedLocation = location
                return location
            }
            .eraseToAnyPublisher()

        let cityPublisher = input.city
            .map { city in
                self.cachedCity = city
                return city
            }
            .eraseToAnyPublisher()

        let radiusPublisher = input.radius
            .map { radius in
                self.cachedRadius = radius
                return radius
            }
            .eraseToAnyPublisher()

        let output = Output(
            location: locationPublisher,
            city: cityPublisher,
            radius: radiusPublisher
        )

        return output
    }
}
