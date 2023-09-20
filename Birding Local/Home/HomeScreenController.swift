//
//  ViewController.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/12/23.
//

import UIKit

class HomeScreenController: UIViewController {
    private lazy var viewModel = HomeScreenViewModel(serviceContainer: ServiceContainer.shared)

    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationAuth()
        registerNotifications()
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(gotInitialLocation), name: NSNotification.Name(NotificationNames.GotInitialLocation.rawValue), object: nil)
    }

    private func checkLocationAuth() {
        // register user for location services, if not authorized, show alert prompting user to open settings
        if let alert = viewModel.locationService.checkLocationAuth() {
            present(alert, animated: true)
        }
    }

    @objc func gotInitialLocation() {
        // view model -> fetch birds
        print("current location", viewModel.locationService.currentLocation)

    }
}

