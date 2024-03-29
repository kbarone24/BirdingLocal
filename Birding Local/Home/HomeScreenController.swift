//
//  ViewController.swift
//  Birding Local
//
//  Created by Kenny Barone on 9/12/23.
//

import UIKit
import CoreLocation
import Combine
import WidgetKit

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

    let refresh = PassthroughSubject<Bool, Never>()
    let fetchInput = PassthroughSubject<(currentLocation: CLLocation?, radius: Double?, useStartIndex: Bool), Never>()
    let city = PassthroughSubject<(passedLocation: CLLocation?, radius: Double?), Never>()

    private lazy var viewModel = HomeScreenViewModel(serviceContainer: ServiceContainer.shared)
    private lazy var subscriptions = Set<AnyCancellable>()

    private lazy var titleView = HomeScreenTitleView()

    private lazy var activityFooterView = ActivityFooterView()

    private lazy var backgroundView = UIImageView(image: UIImage(asset: .CircleBackground))

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
        tableView.backgroundColor = .clear
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 32, right: 0)
        tableView.sectionFooterHeight = 20
        tableView.register(HomeScreenCell.self, forCellReuseIdentifier: HomeScreenCell.reuseID)
        tableView.register(HomeScreenTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HomeScreenTableViewHeader.reuseID)
        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(forceRefresh), for: .valueChanged)
        return refreshControl
    }()

    var isRefreshingPagination = false {
        didSet {
            // show bottom activity indicator during pagination
            DispatchQueue.main.async {
                if self.isRefreshingPagination, !self.datasource.snapshot().itemIdentifiers.isEmpty {
                    self.activityFooterView.isHidden = false
                } else {
                    self.activityFooterView.isHidden = true
                }
            }
        }
    }

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
        view.backgroundColor = .clear

        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        checkLocationAuth()
        registerNotifications()

        let safeArea = view.safeAreaLayoutGuide

        view.addSubview(titleView)
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleViewTap)))
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeArea.snp.top).offset(28)
            $0.leading.trailing.equalToSuperview()
        }

        activityFooterView.isHidden = true
        tableView.tableFooterView = activityFooterView
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        activityIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(60)
        }

        let input = Input(
            refresh: refresh,
            fetchInput: fetchInput,
            city: city
        )

        // just return cached posts and maintain activity animation
        let cachedOutput = viewModel.bindForCachedSightings(to: input)
        cachedOutput.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.applySnapshot(snapshot: snapshot)
            }
            .store(in: &subscriptions)

        let sightingsOutput = viewModel.bindForSightings(to: input)
        sightingsOutput.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.applySnapshot(snapshot: snapshot)
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                self?.isRefreshingPagination = false
            }
            .store(in: &subscriptions)

        let cityOutput = viewModel.bindForCity(to: input)
        cityOutput.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.applySnapshot(snapshot: snapshot)
            }
            .store(in: &subscriptions)


        if viewModel.locationService.gotInitialLocation {
            fetchInput.send((nil, nil, false))
            city.send((passedLocation: nil, radius: nil))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        NotificationCenter.default.addObserver(self, selector: #selector(deniedLocationAccess), name: NSNotification.Name(NotificationNames.DeniedLocationAccess.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setLocationForFirstTime), name: NSNotification.Name(NotificationNames.SetLocationForFirstTime.rawValue), object: nil)
    }

    private func checkLocationAuth() {
        // register user for location services
        viewModel.locationService.checkLocationAuth()
    }

    @objc func gotInitialLocation() {
        // view model -> fetch birds
        fetchInput.send((currentLocation: viewModel.cachedLocation, radius: viewModel.cachedRadius, useStartIndex: false))
        city.send((passedLocation: viewModel.cachedLocation, radius: viewModel.cachedRadius))
    }

    @objc func deniedLocationAccess() {
        fetchInput.send((currentLocation: CLLocation(), radius: 0.0, useStartIndex: false))
        city.send((passedLocation: CLLocation(), radius: 0.0))
    }

    @objc func setLocationForFirstTime() {
        DispatchQueue.main.async {
            let vc = TutorialPageViewController()
            self.present(vc, animated: true)
        }
    }

    @objc func forceRefresh() {
        fetchInput.send((currentLocation: viewModel.cachedLocation, radius: viewModel.cachedRadius, useStartIndex: false))
        city.send((passedLocation: viewModel.cachedLocation, radius: viewModel.cachedRadius))
    }

    @objc func titleViewTap() {
        let vc = LocationEditorController(viewModel: LocationEditorViewModel(
            serviceContainer: ServiceContainer.shared,
            currentLocation: viewModel.cachedLocation ?? CLLocation(),
            city: viewModel.cachedCity ?? "",
            radius: viewModel.cachedRadius
        ))
        DispatchQueue.main.async {
            vc.delegate = self
            self.present(vc, animated: true)
        }
    }
}

extension HomeScreenController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let snapshot = datasource.snapshot()
        if (indexPath.row >= snapshot.numberOfItems - 2) && !isRefreshingPagination {
            isRefreshingPagination = true
            fetchInput.send((currentLocation: viewModel.cachedLocation, radius: viewModel.cachedRadius, useStartIndex: true))
        }
    }
}

extension HomeScreenController: LocationEditorDelegate {
    func finishPassing(radius: Double, location: CLLocation) {
        viewModel.cachedSightings = []
        refresh.send(false)
        city.send((passedLocation: location, radius: radius))

        fetchInput.send((currentLocation: location, radius: radius, useStartIndex: false))
        activityIndicator.startAnimating()
    }
}
