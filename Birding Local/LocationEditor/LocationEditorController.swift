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

protocol LocationEditorDelegate: AnyObject {
    func finishPassing(radius: Double, location: CLLocation)
}

class LocationEditorController: UIViewController {
    typealias Input = LocationEditorViewModel.Input

    weak var delegate: LocationEditorDelegate?
    private let viewModel: LocationEditorViewModel

    private let location = PassthroughSubject<CLLocation, Never>()
    private let city = PassthroughSubject<String?, Never>()
    private let radius = PassthroughSubject<Double, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var activityIndicator = UIActivityIndicatorView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Update Location"
        label.textColor = UIColor(color: .PrimaryBlue)
        label.font = TextStyle.boldedHeader.uiFont
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(withInsets: NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        button.setImage(UIImage(asset: .CloseButton), for: .normal)
        button.addTarget(self, action: #selector(closeTap), for: .touchUpInside)
        return button
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(color: .PrimaryGray)?.withAlphaComponent(0.25)
        return view
    }()

    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.text = "Search by city"
        label.textColor = UIColor(color: .PrimaryGray)
        label.font = TextStyle.heroLabel.uiFont
        return label
    }()

    private lazy var locationContainer: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(color: .PrimaryGray)?.withAlphaComponent(0.25).cgColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))
        return view
    }()

    private lazy var locationPin = UIImageView(image: UIImage(asset: .LocationPin)?.withTintColor(UIColor(color: .PrimaryGray) ?? .gray))

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.textColor = UIColor(color: .PrimaryGray)
        label.font = TextStyle.sublabel.uiFont
        return label
    }()

    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(color: .PrimaryBlue)
        label.font = TextStyle.label.uiFont
        label.layer.cornerRadius = 4
        return label
    }()

    private lazy var radiusContainer = UIView()

    private lazy var radiusLabel: UILabel = {
        let label = UILabel()
        label.text = "Radius"
        label.textColor = UIColor(color: .PrimaryGray)
        label.font = TextStyle.heroLabel.uiFont
        return label
    }()

    private lazy var radiusSlider = RadiusSlider(radius: viewModel.cachedRadius)

    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(color: .PrimaryBlue)
        button.layer.cornerRadius = 4
        button.setAttributedTitle(
            NSAttributedString(
                string: "Save",
                attributes: [
                    .foregroundColor: UIColor(color: .AccentWhite) as Any,
                    .font: TextStyle.button.uiFont
                ]),
            for: .normal)
        button.addTarget(self, action: #selector(applyTap), for: .touchUpInside)
        return button
    }()

    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
   //     mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = true
        mapView.mapType = .mutedStandard
        mapView.delegate = self
        return mapView
    }()

    private lazy var userLocationButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(asset: .CurrentLocationButton), for: .normal)
        button.addTarget(self, action: #selector(currentLocationTap), for: .touchUpInside)
        button.isHidden = true
        return button
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


        view.addSubview(locationContainer)
        locationContainer.snp.makeConstraints {
            $0.top.equalTo(searchLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(separatorLine).inset(20)
            $0.height.equalTo(56)
        }

        locationContainer.addSubview(locationPin)
        locationPin.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
        }

        locationContainer.addSubview(locationLabel)
        locationLabel.snp.makeConstraints {
            $0.leading.equalTo(locationPin.snp.trailing).offset(16)
            $0.bottom.equalTo(locationContainer.snp.centerY).offset(-2)
        }

        locationContainer.addSubview(cityLabel)
        cityLabel.snp.makeConstraints {
            $0.leading.equalTo(locationLabel)
            $0.top.equalTo(locationContainer.snp.centerY).offset(2)
        }

        view.addSubview(radiusContainer)
        radiusContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
            $0.top.equalTo(locationContainer.snp.bottom).offset(4)
        }

        radiusContainer.addSubview(radiusLabel)
        radiusLabel.snp.makeConstraints {
            $0.leading.equalTo(searchLabel)
            $0.top.equalTo(16)
        }

        radiusContainer.addSubview(radiusSlider)

        radiusSlider.delegate = self
        radiusSlider.snp.makeConstraints {
            $0.top.equalTo(radiusLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(locationContainer)
            $0.height.equalTo(50)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }

        view.addSubview(mapView)
        mapView.snp.makeConstraints {
            $0.leading.trailing.equalTo(saveButton)
            $0.top.equalTo(radiusContainer.snp.bottom).offset(16)
            $0.bottom.equalTo(saveButton.snp.top).offset(-16)
        }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)

        mapView.addSubview(userLocationButton)
        userLocationButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(12)
        }

        let input = Input(
            location: location,
            city: city,
            radius: radius)
        let output = viewModel.bind(to: input)

        output.combinedOutput
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (location, city) in
                self?.setMapView(location: location, radius: self?.viewModel.cachedRadius ?? 1000)
                self?.setCity(city: city)
            }
            .store(in: &subscriptions)

        output.radius
            .receive(on: DispatchQueue.main)
            .sink { [weak self] radius in
                self?.setMapView(location: self?.viewModel.cachedLocation ?? CLLocation(), radius: radius)
            }
            .store(in: &subscriptions)

        location.send(viewModel.cachedLocation)
        city.send(viewModel.cachedCity)
        radius.send(viewModel.cachedRadius)
    }

    private func setMapView(location: CLLocation, radius: Double) {
        mapView.setRegion(
            MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radius.inKM() * 1000 * 4,
                longitudinalMeters: radius.inKM() * 1000 * 4
            ),
            animated: true
        )
        addRadiusCircle(location: location.coordinate, radius: radius)
    }

    private func setCity(city: String) {
        cityLabel.text = city
    }

    @objc func closeTap() {
        close()
    }

    @objc func locationTap() {
        DispatchQueue.main.async {
            let searchController = SearchLocationController(viewModel: SearchLocationViewModel(serviceContainer: ServiceContainer.shared))
            searchController.delegate = self
            self.present(searchController, animated: true)
        }
    }

    @objc func currentLocationTap() {
        if let userLocation = viewModel.currentLocation {
            location.send(userLocation)
            city.send(nil)
        }
    }

    @objc func longPress(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }

        let touchLocation = gesture.location(in: mapView)
        let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)

        location.send(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        city.send(nil)
    }

    @objc func applyTap() {
        delegate?.finishPassing(radius: viewModel.cachedRadius, location: viewModel.cachedLocation)
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
        // remove any already-drawn overlays
        for overlay in mapView.overlays {
            mapView.removeOverlay(overlay)
        }

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

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard let userLocation = viewModel.currentLocation else {
            userLocationButton.isHidden = true
            return
        }
        userLocationButton.isHidden = mapView.centerCoordinate == userLocation.coordinate
    }
}

extension LocationEditorController: SearchLocationDelegate {
    func finishPassing(searchResult: SearchResult) {
        location.send(CLLocation(latitude: searchResult.coordinate?.latitude ?? 0.0, longitude: searchResult.coordinate?.longitude ?? 0.0))
        city.send(searchResult.titleString)
    }
}

extension LocationEditorController: PrivacySliderDelegate {
    func finishPassing(radius: Double) {
        self.radius.send(radius)
    }
}
