//
//  LocationEditor.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/25/23.
//

import Foundation
import UIKit
import Combine
import MapKit

class LocationEditorController: UIViewController {
    typealias Input = LocationEditorViewModel.Input
    typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let viewModel: LocationEditorViewModel
    private let searchText = PassthroughSubject<String, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var dataSource: DataSource = {
        let dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .item(let searchResult):
                let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseID, for: indexPath) as? SearchResultCell
                //  cell?.configure(searchResult: searchResult)
                return cell
            }
        }
        return dataSource
    }()
    
    enum Section: Hashable {
        case main
    }

    enum Item: Hashable {
        case item(searchResult: SearchResult)
    }

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = UIColor(named: "SpotBlack")
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 300, right: 0)
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseID)
        table.rowHeight = UITableView.automaticDimension
        return table
    }()

    private lazy var activityIndicator = UIActivityIndicatorView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Update Location"
        label.textColor = Colors.PrimaryBlue.color
        label.font = Fonts.SFProBold.font(with: 20)
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(withInsets: NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        button.setImage(UIImage(named: "CloseButton"), for: .normal)
        button.addTarget(self, action: #selector(closeTap), for: .touchUpInside)
        return button
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.PrimaryGray.color.withAlphaComponent(0.25)
        return view
    }()

    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.text = "Search by city"
        label.textColor = Colors.PrimaryGray.color
        label.font = Fonts.SFProMedium.font(with: 16)
        return label
    }()

    private lazy var searchContainer: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = Colors.PrimaryGray.color.withAlphaComponent(0.25).cgColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchTap)))
        return view
    }()

    private lazy var locationPin = UIImageView(image: UIImage(named:"LocationPin")?.withTintColor(Colors.PrimaryGray.color))

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.textColor = Colors.PrimaryGray.color
        label.font = Fonts.SFProMedium.font(with: 12)
        return label
    }()

    private lazy var searchButton: UILabel = {
        let label = UILabel()
        label.text = viewModel.city
        label.textColor = Colors.PrimaryBlue.color
        label.font = Fonts.SFProMedium.font(with: 14)
        label.layer.cornerRadius = 4
        return label
    }()

    private lazy var radiusContainer: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = Colors.PrimaryGray.color.withAlphaComponent(0.25).cgColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(radiusTap)))
        return view
    }()

    private lazy var radiusLabel: UILabel = {
        let label = UILabel()
        label.text = "Radius"
        label.textColor = Colors.PrimaryGray.color
        label.font = Fonts.SFProMedium.font(with: 12)
        return label
    }()

    private lazy var radiusButton: UILabel = {
        let label = UILabel()
        label.text = "\(viewModel.radius) mi"
        label.textColor = Colors.PrimaryBlue.color
        label.font = Fonts.SFProMedium.font(with: 14)
        label.layer.cornerRadius = 4
        return label
    }()

    private lazy var downCarat = UIImageView(image: UIImage(named: "DownCarat"))

    private lazy var applyButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = Colors.PrimaryBlue.color
        button.layer.cornerRadius = 4
        button.setAttributedTitle(
            NSAttributedString(
                string: "Apply",
                attributes: [
                    .foregroundColor: Colors.AccentWhite.color,
                    .font: Fonts.SFProBold.font(with: 16)
                ]),
            for: .normal)
        button.addTarget(self, action: #selector(applyTap), for: .touchUpInside)
        return button
    }()

    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.mapType = .mutedStandard
        mapView.delegate = self
        return mapView
    }()

    init(viewModel: LocationEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(27)
            $0.centerX.equalToSuperview()
        }

        view.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.top.equalTo(15)
            $0.trailing.equalTo(-25)
        }

        view.addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(5)
            $0.height.equalTo(1)
            $0.top.equalTo(titleLabel.snp.bottom).offset(27)
        }

        view.addSubview(searchLabel)
        searchLabel.snp.makeConstraints {
            $0.leading.equalTo(separatorLine).offset(20)
            $0.top.equalTo(separatorLine).offset(16)
        }


        view.addSubview(searchContainer)
        searchContainer.snp.makeConstraints {
            $0.top.equalTo(searchLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(separatorLine).inset(20)
            $0.height.equalTo(56)
        }

        searchContainer.addSubview(locationPin)
        locationPin.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
        }

        searchContainer.addSubview(locationLabel)
        locationLabel.snp.makeConstraints {
            $0.leading.equalTo(locationPin.snp.trailing).offset(16)
            $0.bottom.equalTo(searchContainer.snp.centerY).offset(-2)
        }

        searchContainer.addSubview(searchButton)
        searchButton.snp.makeConstraints {
            $0.leading.equalTo(locationLabel)
            $0.top.equalTo(searchContainer.snp.centerY).offset(2)
        }

        view.addSubview(radiusContainer)
        radiusContainer.snp.makeConstraints {
            $0.leading.trailing.height.equalTo(searchContainer)
            $0.top.equalTo(searchContainer.snp.bottom).offset(16)
        }

        radiusContainer.addSubview(radiusLabel)
        radiusLabel.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.bottom.equalTo(radiusContainer.snp.centerY).offset(-2)
        }

        radiusContainer.addSubview(radiusButton)
        radiusButton.snp.makeConstraints {
            $0.leading.equalTo(radiusLabel)
            $0.top.equalTo(radiusContainer.snp.centerY).offset(2)
        }

        radiusContainer.addSubview(downCarat)
        downCarat.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(1)
            $0.trailing.equalTo(-16)
        }

        view.addSubview(applyButton)
        applyButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(radiusContainer)
            $0.height.equalTo(50)
            $0.bottom.equalTo(-20)
        }

        view.addSubview(mapView)
        mapView.snp.makeConstraints {
            $0.leading.trailing.equalTo(applyButton)
            $0.top.equalTo(radiusContainer.snp.bottom).offset(16)
            $0.bottom.equalTo(applyButton.snp.top).offset(-32)
        }

        mapView.setRegion(
            MKCoordinateRegion(
                center: viewModel.currentLocation.coordinate,
                latitudinalMeters: viewModel.radius.inKM() * 1000 * 4,
                longitudinalMeters: viewModel.radius.inKM() * 1000 * 4
            ),
            animated: false
        )
        addRadiusCircle(location: viewModel.currentLocation.coordinate, radius: viewModel.radius)
    }

    @objc func closeTap() {
        close()
    }

    @objc func searchTap() {
        print("search")
    }

    @objc func radiusTap() {
        print("tap")
    }

    @objc func applyTap() {
        //TODO: configure delegate and passback
        close()
    }

    private func close() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}

extension LocationEditorController: MKMapViewDelegate {
    func addRadiusCircle(location: CLLocationCoordinate2D, radius: Double) {
        let circle = MKCircle(center: location, radius: radius.inKM() * 1000)
        mapView.addOverlay(circle)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: circleOverlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
