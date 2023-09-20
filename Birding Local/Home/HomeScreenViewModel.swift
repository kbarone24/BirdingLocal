//
//  HomeScreenViewModel.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import Combine
import IdentifiedCollections

class HomeScreenViewModel {
    let ebirdService: EBirdServiceProtocol
    let locationService: LocationServiceProtocol

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
}
