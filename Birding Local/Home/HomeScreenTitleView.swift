//
//  HomeScreenTitleView.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/14/23.
//

import Foundation
import UIKit

class HomeScreenTitleView: UIView {

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

    private lazy var editLocation: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Fonts.SFProRegular.uifont(with: 14)
        label.attributedText = NSMutableAttributedString(string: "Update Location", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.kern: -0.41])
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(locationView)
        locationView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
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

        addSubview(editLocation)
        editLocation.snp.makeConstraints {
            $0.top.equalTo(8)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    func configure(city: String, radius: Double) {
        let attributes = [NSAttributedString.Key.kern: -0.41]
        cityLabel.attributedText = NSAttributedString(string: city, attributes: attributes)
        radiusLabel.attributedText = NSAttributedString(string: "\(Int(radius)) mile radius", attributes: attributes)

        radiusLabel.isHidden = city.isEmpty || radius == 0
        separatorView.isHidden = city.isEmpty || radius == 0
        locationPinIcon.isHidden = city.isEmpty || radius == 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
