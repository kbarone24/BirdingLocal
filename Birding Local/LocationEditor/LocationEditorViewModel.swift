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
        let city: PassthroughSubject<String?, Never>
        let radius: PassthroughSubject<Double, Never>
    }

    struct Output {
        let combinedOutput: AnyPublisher<(CLLocation, String), Never>
        let radius: AnyPublisher<Double, Never>
    }

    let locationService: LocationServiceProtocol
    var cachedLocation: CLLocation
    var cachedCity: String
    var cachedRadius: Double

    var currentLocation: CLLocation? {
        return locationService.currentLocation
    }

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
        let combinedPublisher = Publishers.CombineLatest(input.location, input.city)
            .flatMap { [unowned self] (location, city) -> AnyPublisher<(CLLocation, String), Never> in
                self.cachedLocation = location

                if let city = city {
                    self.cachedCity = city
                    return Just((location, city)).eraseToAnyPublisher()
                    
                } else {
                    // Fetch the city based on the location and return a publisher for the city
                    return self.getCity(for: location)
                        .map { [weak self] fetchedCity -> (CLLocation, String) in
                            self?.cachedCity = fetchedCity
                            return (location, fetchedCity)
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()


        let radiusPublisher = input.radius
            .map { radius in
                self.cachedRadius = radius
                return radius
            }
            .eraseToAnyPublisher()

        let output = Output(
            combinedOutput: combinedPublisher,
            radius: radiusPublisher
        )

        return output
    }

    private func getCity(for location: CLLocation) -> AnyPublisher<(String), Never> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.success(""))
                    return
                }
                Task {
                    let city = await self.locationService.getCity(passedLocation: self.cachedLocation)
                    promise(.success(city.city ?? ""))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
