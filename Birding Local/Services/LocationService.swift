//
//  LocationService.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import CoreLocation
import UIKit
import WidgetKit

protocol LocationServiceProtocol {
    var currentLocation: CLLocation? { get set }
    var gotInitialLocation: Bool { get set }
    func checkLocationAuth()
    func currentLocationStatus() -> CLAuthorizationStatus
    func getCity(passedLocation: CLLocation?) async -> (city: String?, location: CLLocation?)
}

final class LocationService: NSObject, LocationServiceProtocol {
    var currentLocation: CLLocation?
    var gotInitialLocation = false

    private lazy var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func checkLocationAuth() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // prompt user to open their settings if they havent allowed location services

        case .restricted:
          //  return locationAlert()
            return

        case .denied:
            print("denied")

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()

        @unknown default:
            return
        }
    }

    func currentLocationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    func getCity(passedLocation: CLLocation?) async -> (city: String?, location: CLLocation?) {
        await withUnsafeContinuation { continuation in
            Task {
                guard let location = passedLocation ?? currentLocation else {
                    continuation.resume(returning: (city: nil, location: nil))
                    return
                }
                
                var addressString = ""
                let locale = Locale(identifier: "en")
                CLGeocoder().reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, error in
                    guard error == nil, let placemark = placemarks?.first else {
                        continuation.resume(returning: (nil, nil))
                        return
                    }

                    if let locality = placemark.locality {
                        addressString = locality
                    }

                    if let country = placemark.country {
                        if !addressString.isEmpty {
                            addressString += ", "
                        }
                        // show city/state if US city, city/country if intl
                        if country == "United States", let administrativeArea = placemark.administrativeArea {
                            addressString += administrativeArea
                        } else {
                            addressString += country
                        }
                    }

                    continuation.resume(returning: (city: addressString, location: location))
                    self.saveToAppGroup(city: addressString)
                }
            }
        }
    }

    private func saveToAppGroup(city: String) {
        // save city data to App Group for use in widget
        let sharedUserDefaults = UserDefaults(suiteName: AppGroupNames.defaultGroup.rawValue)
        sharedUserDefaults?.set(city, forKey: "city")
        sharedUserDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        self.currentLocation = location

        // notification for user first responding to notification request. Will notify home screen to fetch birds based on user location
        if !gotInitialLocation {
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NotificationNames.GotInitialLocation.rawValue)))
            gotInitialLocation = true
        }
    }
}
