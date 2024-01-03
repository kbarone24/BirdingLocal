//
//  SliderPosition.swift
//  Birding Local
//
//  Created by Kenny Barone on 12/29/23.
//

import Foundation

enum SliderPosition: String, CaseIterable {
    case left = "0.25"
    case leftCenter = "0.5"
    case center = "1"
    case rightCenter = "2"
    case right = "5"

    var position: Int {
        return Self.allCases.firstIndex(of: self) ?? -1
    }

    var radius: Double {
        return Double(rawValue) ?? 0
    }

    init(position: Int) {
        guard let value = Self.allCases.first(where: { $0.position == position }) else {
            self = .left
            return
        }
        self = value
    }

    init(radius: Double) {
        guard let value = Self.allCases.first(where: { $0.radius == radius }) else {
            self = .left
            return
        }
        self = value
    }
}
