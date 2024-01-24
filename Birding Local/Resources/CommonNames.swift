//
//  ColorsAndFonts.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/12/23.
//

import Foundation
import UIKit
import SwiftUI

enum Colors: String {
    case AccentBlue
    case AccentGray
    case AccentWhite
    case PrimaryBlue
    case PrimaryGray
    case SecondaryYellow

    var uicolor: UIColor {
        return UIColor(named: rawValue) ?? .clear
    }

    var color: Color {
        return Color(rawValue)
    }
}

enum Fonts: String {
    case SFProBold = "SFProText-Bold"
    case SFProMedium = "SFProText-Medium"
    case SFProRegular = "SFProText-Regular"
    case SFProSemibold = "SFProText-Semibold"

    func uifont(with size: CGFloat) -> UIFont {
        return UIFont(name: rawValue, size: size) ?? UIFont()
    }

    func font(with size: CGFloat) -> Font {
        return Font.custom(rawValue, size: size)
    }
}

enum NotificationNames: String {
    case GotInitialLocation
}

enum AppGroupNames: String {
    case defaultGroup = "Group.BirdingLocal"
}
