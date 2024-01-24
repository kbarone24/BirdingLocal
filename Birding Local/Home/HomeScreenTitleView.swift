//
//  HomeScreenTitleView.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/14/23.
//

import Foundation
import UIKit

class HomeScreenTitleView: UIView {
    private var currentLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "Current Location"
        label.textColor = Colors.AccentWhite.uicolor
        label.font = Fonts.SFProRegular.uifont(with: 14)
        label.isHidden = true
        return label
    }()

    private lazy var locationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var locationPinIcon: UIImageView = {
        let view = UIImageView(image: UIImage(named: "LocationPin"))
        view.isHidden = true
        return view
    }()

    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.AccentWhite.uicolor
        label.font = Fonts.SFProBold.uifont(with: 14)
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.AccentWhite.uicolor
        view.layer.cornerRadius = 3.5 / 2
        view.isHidden = true
        return view
    }()

    private lazy var radiusLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.AccentWhite.uicolor
        label.font = Fonts.SFProBold.uifont(with: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(currentLocationLabel)
        currentLocationLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.bottom.equalTo(self.snp.centerY).offset(-2)
            $0.centerX.equalToSuperview()
        }

        addSubview(locationView)
        locationView.snp.makeConstraints {
            $0.top.equalTo(self.snp.centerY).offset(2)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        locationView.addSubview(locationPinIcon)
        locationPinIcon.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        locationView.addSubview(cityLabel)
        cityLabel.snp.makeConstraints {
            $0.leading.equalTo(locationPinIcon.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        locationView.addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.leading.equalTo(cityLabel.snp.trailing).offset(5)
            $0.centerY.equalToSuperview()
            $0.height.width.equalTo(3.5)
        }

        locationView.addSubview(radiusLabel)
        radiusLabel.snp.makeConstraints {
            $0.leading.equalTo(separatorView.snp.trailing).offset(5)
            $0.trailing.centerY.equalToSuperview()
        }
    }

    func configure(city: String, radius: Double) {
        cityLabel.text = city
        radiusLabel.text = "\(radius) mile radius"

        currentLocationLabel.isHidden = city.isEmpty || radius == 0
        radiusLabel.isHidden = city.isEmpty || radius == 0
        separatorView.isHidden = city.isEmpty || radius == 0
        locationPinIcon.isHidden = city.isEmpty
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
