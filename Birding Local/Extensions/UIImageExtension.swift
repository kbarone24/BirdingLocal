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
        case CurrentLocationButton
        case DefaultBird
        case DownCarat
        case LocationPin
        case TutorialImage0
        case TutorialImage1
        case TutorialImage2
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

extension UIImage {
    static func gradientImage(bounds: CGRect, colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint, locations: [NSNumber]?) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        let renderer = UIGraphicsImageRenderer(bounds: bounds)

        return renderer.image { context in
            gradientLayer.render(in: context.cgContext)
        }
    }
}
// reference: https://medium.com/academy-poa/how-to-create-a-uiprogressview-with-gradient-progress-in-swift-2d1fa7d26f24
