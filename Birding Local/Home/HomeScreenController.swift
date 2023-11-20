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

    let fetchInput = PassthroughSubject<(radius: Double?, useStartIndex: Bool), Never>()
    let city = PassthroughSubject<String?, Never>()

    private lazy var viewModel = HomeScreenViewModel(serviceContainer: ServiceContainer.shared)
    private lazy var subscriptions = Set<AnyCancellable>()

    private lazy var titleView = HomeScreenTitleView()

    private lazy var activityFooterView = ActivityFooterView()

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
                    print("unhide footer")
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
        //TODO: gradient background
        view.backgroundColor = Colors.PrimaryBlue.color

        checkLocationAuth()
        registerNotifications()

        view.addSubview(titleView)
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleViewTap)))
        titleView.snp.makeConstraints {
            $0.top.equalTo(48)
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
            fetchInput: fetchInput,
            city: city
        )
        let sightingsOutput = viewModel.bindForSightings(to: input)
        sightingsOutput.snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                // apply to datasource
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
                // apply to datasource
                self?.applySnapshot(snapshot: snapshot)
            }
            .store(in: &subscriptions)


        if viewModel.locationService.gotInitialLocation {
            fetchInput.send((nil, false))
            city.send(nil)
        }
        // else refresh sent by internal noti
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
        fetchInput.send((radius: nil, useStartIndex: false))
        city.send(nil)
    }

    @objc func forceRefresh() {
        fetchInput.send((radius: nil, useStartIndex: false))
        city.send(nil)
    }

    @objc func titleViewTap() {
        let vc = LocationEditorController(viewModel: LocationEditorViewModel(
            serviceContainer: ServiceContainer.shared,
            currentLocation: viewModel.cachedLocation ?? CLLocation(),
            city: viewModel.cachedCity ?? "",
            radius: viewModel.cachedRadius
        ))
        DispatchQueue.main.async {
            self.present(vc, animated: true)
        }
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let snapshot = datasource.snapshot()
        if (indexPath.row >= snapshot.numberOfItems - 2) && !isRefreshingPagination {
            isRefreshingPagination = true
            fetchInput.send((radius: nil, useStartIndex: true))
        }
    }
}
