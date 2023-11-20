//
//  UIButton.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/25/23.
//

import UIKit

extension UIButton {
    convenience init(withInsets insets: NSDirectionalEdgeInsets) {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = insets
        self.init(configuration: configuration)
    }
}
