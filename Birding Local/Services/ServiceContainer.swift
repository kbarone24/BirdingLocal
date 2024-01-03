//
//  ServiceContainer.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation

final class ServiceContainer {
    enum RegistrationError: Error {
        case alreadyRegistered
        case readOnlyViolation
    }

    enum FetchError: Error {
        case notFound
    }

    static let shared = ServiceContainer()

    private(set) var locationService: LocationServiceProtocol?
    private(set) var ebirdService: EBirdServiceProtocol?
    private (set) var mapsService: MapsService?

    func register<T>(service: T, for keyPath: KeyPath<ServiceContainer, T?>) throws {

        guard let writeableKeyPath = keyPath as? ReferenceWritableKeyPath else {
            throw RegistrationError.readOnlyViolation
        }

        guard self[keyPath: writeableKeyPath] == nil else {
            throw RegistrationError.alreadyRegistered
        }

        self[keyPath: writeableKeyPath] = service
    }

    func service<T>(for keyPath: KeyPath<ServiceContainer, T?>) throws -> T {
        guard let service = self[keyPath: keyPath] else {
            throw FetchError.notFound
        }
        return service
    }
}
