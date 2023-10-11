//
//  ViewController.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/12/23.
//

import UIKit
import CoreLocation
import Combine

class HomeScreenController: UIViewController {
    enum Section: Hashable {
        case main
    }

    enum Item: Hashable {
        case item(sighting: BirdSighting)
    }

    typealias Input = HomeScreenViewModel.Input
    typealias Output = HomeScreenViewModel.Output
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias DataSource = UITableViewDiffableDataSource<Section, Item>

    let refresh = PassthroughSubject<Bool, Never>()

    private lazy var viewModel = HomeScreenViewModel(serviceContainer: ServiceContainer.shared)
    private lazy var subscriptions = Set<AnyCancellable>()

    //TODO: set up diffable data source

    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationAuth()
        registerNotifications()

        let input = Input(
            refresh: refresh
        )
        let output = viewModel.bind(to: input)

        output.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                print("sink!")
                // apply to datasource
             //   self?.datasource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &subscriptions)

        if viewModel.locationService.gotInitialLocation {
            // otherwise refresh sent by internal noti
            refresh.send(true)
        }
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
        refresh.send(true)
    }
}

