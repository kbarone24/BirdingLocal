//
//  File.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/20/24.
//

import Foundation
import UIKit

class OnboardingButton: UIButton {
    init() {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 4

        let color = UIColor(color: .AccentBlue)
        setTitleColor(color, for: .normal)
        titleLabel?.font = TextStyle.button.uiFont
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
