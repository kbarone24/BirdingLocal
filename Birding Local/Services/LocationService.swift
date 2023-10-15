//
//  LocationService.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/20/23.
//

import Foundation
import CoreLocation
import UIKit

protocol LocationServiceProtocol {
    var currentLocation: CLLocation? { get set }
    var gotInitialLocation: Bool { get set }
    func checkLocationAuth() -> UIAlertController?
    func currentLocationStatus() -> CLAuthorizationStatus
    func locationAlert() -> UIAlertController
    func getCity() async -> String?
}

final class LocationService: NSObject, LocationServiceProtocol {
    var currentLocation: CLLocation?
    var gotInitialLocation = false
    
    private lazy var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    @discardableResult
    func checkLocationAuth() -> UIAlertController? {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            // prompt user to open their settings if they havent allowed location services
            return nil

        case .restricted, .denied:
            return locationAlert()

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            return nil

        @unknown default:
            return nil
        }
    }

    func currentLocationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    func locationAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "Birding Local needs your location to find birds near you",
            message: nil,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:])
                }
            }
        )

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
            }
        )

        return alert
    }

    func getCity() async -> String? {
        await withUnsafeContinuation { continuation in
            Task {
                guard let currentLocation else {
                    continuation.resume(returning: "")
                    return
                }
                
                var addressString = ""
                let locale = Locale(identifier: "en")
                CLGeocoder().reverseGeocodeLocation(currentLocation, preferredLocale: locale) { placemarks, error in
                    guard error == nil, let placemark = placemarks?.first else {
                        continuation.resume(returning: nil)
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
                    continuation.resume(returning: addressString)
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
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
