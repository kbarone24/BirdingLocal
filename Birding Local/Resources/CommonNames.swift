//
//  ColorsAndFonts.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/12/23.
//

import Foundation
import UIKit

enum Colors: String {
    case AccentBlue
    case AccentGray
    case AccentWhite
    case PrimaryBlue
    case PrimaryGray
    case SecondaryYellow

    var color: UIColor {
        return UIColor(named: rawValue) ?? .clear
    }
}

enum Fonts: String {
    case SFProBold = "SFProText-Bold"
    case SFProMedium = "SFProText-Medium"
    case SFProRegular = "SFProText-Regular"
    case SFProSemibold = "SFProText-Semibold"

    func font(with size: CGFloat) -> UIFont {
        return UIFont(name: rawValue, size: size) ?? UIFont()
    }
}

enum NotificationNames: String {
    case GotInitialLocation
}
