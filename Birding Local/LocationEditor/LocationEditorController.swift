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
    private let city = PassthroughSubject<String, Never>()
    private let radius = PassthroughSubject<Double, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var activityIndicator = UIActivityIndicatorView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Update Location"
        label.textColor = Colors.PrimaryBlue.uicolor
        label.font = Fonts.SFProBold.uifont(with: 20)
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
        view.backgroundColor = Colors.PrimaryGray.uicolor.withAlphaComponent(0.25)
        return view
    }()

    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.text = "Search by city"
        label.textColor = Colors.PrimaryGray.uicolor
        label.font = Fonts.SFProMedium.uifont(with: 16)
        return label
    }()

    private lazy var locationContainer: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = Colors.PrimaryGray.uicolor.withAlphaComponent(0.25).cgColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(locationTap)))
        return view
    }()

    private lazy var locationPin = UIImageView(image: UIImage(named:"LocationPin")?.withTintColor(Colors.PrimaryGray.uicolor))

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Location"
        label.textColor = Colors.PrimaryGray.uicolor
        label.font = Fonts.SFProMedium.uifont(with: 12)
        return label
    }()

    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.PrimaryBlue.uicolor
        label.font = Fonts.SFProMedium.uifont(with: 14)
        label.layer.cornerRadius = 4
        return label
    }()

    private lazy var radiusContainer = UIView()

    private lazy var radiusLabel: UILabel = {
        let label = UILabel()
        label.text = "Radius"
        label.textColor = Colors.PrimaryGray.uicolor
        label.font = Fonts.SFProMedium.uifont(with: 16)
        return label
    }()

    private lazy var radiusSlider = RadiusSlider(radius: viewModel.cachedRadius)

    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = Colors.PrimaryBlue.uicolor
        button.layer.cornerRadius = 4
        button.setAttributedTitle(
            NSAttributedString(
                string: "Save",
                attributes: [
                    .foregroundColor: Colors.AccentWhite.uicolor,
                    .font: Fonts.SFProBold.uifont(with: 16)
                ]),
            for: .normal)
        button.addTarget(self, action: #selector(applyTap), for: .touchUpInside)
        return button
    }()

    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        // TODO: enable user interaction with ability to change radius
        mapView.isUserInteractionEnabled = false
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

        let input = Input(
            location: location,
            city: city,
            radius: radius)
        let output = viewModel.bind(to: input)

        output.location
            .sink { [weak self] location in
                self?.setMapView(location: location, radius: self?.viewModel.cachedRadius ?? 1000)
            }
            .store(in: &subscriptions)

        output.city
            .sink { [weak self] city in
                self?.setCity(city: city)
            }
            .store(in: &subscriptions)

        output.radius
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

    @objc func radiusTap() {
        print("tap")
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
