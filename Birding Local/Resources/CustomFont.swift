//
//  CustomFont.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/5/24.
//

import UIKit
import SwiftUI

enum FontName: String {
    case SFProBold = "SFProText-Bold"
    case SFProMedium = "SFProText-Medium"
    case SFProRegular = "SFProText-Regular"
    case SFProSemibold = "SFProText-Semibold"

    var name: String {
        return self.rawValue
    }
}

struct CustomFont {
    let font: FontName
    let size: CGFloat
    let style: UIFont.TextStyle
}

enum TextStyle {
    case heroLabel
    case label
    case sublabel

    case heroHeader
    case boldedHeader
    case subheader
    case button

    case widgetHeader
    case widgetLabel
    case custom(fontName: FontName, size: CGFloat)
}

extension TextStyle {
    private var customFont: CustomFont {
        switch self {
        case .heroLabel:
            return CustomFont(font: .SFProMedium, size: 16, style: .body)
        case .label:
            return CustomFont(font: .SFProMedium, size: 14, style: .body)
        case .sublabel:
            return CustomFont(font: .SFProMedium, size: 12, style: .body)

        case .heroHeader:
            return CustomFont(font: .SFProSemibold, size: 24, style: .headline)
        case .boldedHeader:
            return CustomFont(font: .SFProBold, size: 20, style: .headline)
        case .subheader:
            return CustomFont(font: .SFProBold, size: 14, style: .subheadline)


        case .button:
            return CustomFont(font: .SFProBold, size: 16, style: .title2)

        case .widgetHeader:
            return CustomFont(font: .SFProRegular, size: 10, style: .body)
        case .widgetLabel:
            return CustomFont(font: .SFProMedium, size: 12, style: .body)

        case .custom(fontName: let font, size: let size):
            return CustomFont(font: font, size: size, style: .body)
        }
    }
}

extension TextStyle {
    var uiFont: UIFont {
        guard let font = UIFont(name: customFont.font.name, size: customFont.size) else {
            return UIFont.preferredFont(forTextStyle: customFont.style)
        }

        let fontMetrics = UIFontMetrics(forTextStyle: customFont.style)
        return fontMetrics.scaledFont(for: font)
    }

    var font: Font {
        return Font(UIFont(name: customFont.font.name, size: customFont.size)!)
    }
}

// reference: https://www.ramshandilya.com/blog/design-system-typography/


