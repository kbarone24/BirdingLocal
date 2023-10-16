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

    func font(with size: FontSize) -> UIFont {
        return UIFont(name: rawValue, size: size.rawValue) ?? UIFont()
    }
}

enum FontSize: CGFloat {
    case header = 25
    case subheader = 20
    case label = 18
    case sublabel = 14
}

enum NotificationNames: String {
    case GotInitialLocation
}
