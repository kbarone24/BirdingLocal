//
//  UIColorExtension.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/5/24.
//

import UIKit

extension UIColor {
    convenience init?(color: CustomColor) {
        self.init(named: color.rawValue)
    }
}
