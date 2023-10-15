//
//  UITableViewCellExtension.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/12/23.
//

import UIKit

extension UITableViewCell {
    static var reuseID: String {
        "\(Self.self)"
    }
}

extension UITableViewHeaderFooterView {
    static var reuseID: String {
        "\(Self.self)"
    }
}
