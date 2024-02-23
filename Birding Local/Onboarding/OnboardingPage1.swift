//
//  OnboardingPage2.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/18/24.
//

import Foundation
import UIKit

class OnboardingPage1: UIViewController {
    private lazy var tutorialImage: UIImageView = {
        let view = UIImageView(image: UIImage(asset: .TutorialImage1))
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = "Add the widget to your home screen"
        label.textColor = .white
        label.font = TextStyle.boldedHeader.uiFont
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    private lazy var sublabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the Plus button in the top left corner"
        label.textColor = .white
        label.font = TextStyle.heroLabel.uiFont
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        view.backgroundColor = .clear
        let safeArea = view.safeAreaLayoutGuide

        view.addSubview(sublabel)
        sublabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(safeArea.snp.bottom).offset(-114)
        }

        view.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(sublabel.snp.top).offset(-16)
        }

        view.addSubview(tutorialImage)
        tutorialImage.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(label.snp.top).offset(-56)
            $0.top.greaterThanOrEqualTo(safeArea.snp.top).offset(32)
        }
    }
}
