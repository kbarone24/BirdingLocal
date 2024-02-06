//
//  UIImageExtension.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/14/23.
//

import UIKit
extension UIImage {
    enum Asset: String {
        case BackArrow
        case CircleBackground
        case CloseButton
        case DefaultBird
        case DownCarat
        case LocationPin
    }

    convenience init?(asset: Asset) {
        self.init(named: asset.rawValue)
    }

    /*
    convenience init?(symbol: SFSymbol, configuration: Configuration?) {
        self.init(systemName: symbol.rawValue, withConfiguration: configuration)
    }
    */
}

extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
