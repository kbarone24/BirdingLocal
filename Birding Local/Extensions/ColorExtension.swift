//
//  ColorExtension.swift
//  Birding Local
//
//  Created by Kenny Barone on 2/5/24.
//

import Foundation
import SwiftUI

extension Color {
    init?(color: CustomColor) {
        self.init(color.rawValue)
    }
}

