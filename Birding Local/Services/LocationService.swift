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
    var cachedCity: String? { get set }
    var gotInitialLocation: Bool { get set }
    func checkLocationAuth() -> UIAlertController?
    func currentLocationStatus() -> CLAuthorizationStatus
    func locationAlert() -> UIAlertController
}

final class LocationService: NSObject, LocationServiceProtocol {
    var currentLocation: CLLocation?
    var cachedCity: String?
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
