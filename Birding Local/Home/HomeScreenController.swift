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
        case main(radius: Double, city: String)
    }

    enum Item: Hashable {
        case item(sighting: BirdSighting)
    }

    typealias Input = HomeScreenViewModel.Input
    typealias Output = HomeScreenViewModel.Output
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias DataSource = UITableViewDiffableDataSource<Section, Item>

    let radius = PassthroughSubject<Double, Never>()
    let city = PassthroughSubject<String?, Never>()

    private lazy var viewModel = HomeScreenViewModel(serviceContainer: ServiceContainer.shared)
    private lazy var subscriptions = Set<AnyCancellable>()

    private lazy var titleView = HomeScreenTitleView()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = .white
        view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.rowHeight = 118
        tableView.backgroundColor = Colors.PrimaryBlue.color
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 48, right: 0)
        tableView.register(HomeScreenCell.self, forCellReuseIdentifier: HomeScreenCell.reuseID)
        tableView.register(HomeScreenTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HomeScreenTableViewHeader.reuseID)
        return tableView
    }()

    private(set) lazy var datasource: DataSource = {
        let dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            switch item {
            case .item(sighting: let sighting):
                let cell = tableView.dequeueReusableCell(withIdentifier: HomeScreenCell.reuseID, for: indexPath) as? HomeScreenCell
                cell?.configure(sighting: sighting)
                return cell
            }
        }
        return dataSource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO: gradient background
        view.backgroundColor = Colors.PrimaryBlue.color

        checkLocationAuth()
        registerNotifications()

        view.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.top.equalTo(48)
            $0.leading.trailing.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        activityIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(60)
        }

        let input = Input(
            radius: radius,
            city: city
        )
        let sightingsOutput = viewModel.bindForSightings(to: input)
        sightingsOutput.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                // apply to datasource
                self?.applySnapshot(snapshot: snapshot)
                self?.activityIndicator.stopAnimating()
            }
            .store(in: &subscriptions)

        let cityOutput = viewModel.bindForCity(to: input)
        cityOutput.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                // apply to datasource
                self?.applySnapshot(snapshot: snapshot)
            }
            .store(in: &subscriptions)
        

        if viewModel.locationService.gotInitialLocation {
            // otherwise refresh sent by internal noti
            radius.send(viewModel.cachedRadius)
            city.send(nil)
        }
    }

    private func applySnapshot(snapshot: Snapshot) {
        datasource.apply(snapshot, animatingDifferences: false)
        // configure title view
        if let section = self.datasource.snapshot().sectionIdentifiers.first {
            switch section {
            case .main(radius: let radius, city: let city):
                self.titleView.configure(city: city, radius: radius)
            }
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
        radius.send(viewModel.cachedRadius)
        city.send(nil)
    }
}

extension HomeScreenController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        54
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !datasource.snapshot().sectionIdentifiers.isEmpty else { return UIView() }
        let section = datasource.snapshot().sectionIdentifiers[section]
        switch section {
        case .main:
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: HomeScreenTableViewHeader.reuseID) as? HomeScreenTableViewHeader
            header?.configure(title: "Nearby sightings")
            return header
        }
    }
}
