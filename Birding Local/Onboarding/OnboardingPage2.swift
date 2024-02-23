//
//  OnboardingPage3.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/18/24.
//

import Foundation
import UIKit

protocol OnboardingDelegate: AnyObject {
    func closeOnboarding()
}

class OnboardingPage2: UIViewController {
    weak var delegate: OnboardingDelegate?

    private lazy var tutorialImage: UIImageView = {
        let view = UIImageView(image: UIImage(asset: .TutorialImage2))
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = "Search for Birding Local and add widget"
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

    private lazy var button: OnboardingButton = {
        let button = OnboardingButton()
        button.setAttributedTitle(
            NSAttributedString(
                string: "Let's go",
                attributes: [.kern: -0.41]
            ), for: .normal)
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        view.backgroundColor = .clear
        let safeArea = view.safeAreaLayoutGuide

        view.addSubview(button)
        button.snp.makeConstraints {
            $0.bottom.equalTo(safeArea.snp.bottom).offset(-8)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(50)
        }

        view.addSubview(sublabel)
        sublabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(button.snp.top).offset(-56)
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

    @objc func tap() {
        delegate?.closeOnboarding()
    }
}
