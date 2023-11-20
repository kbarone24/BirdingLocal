//
//  DoubleExtension.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/15/23.
//

import Foundation

extension Double {
    func inKM() -> Double {
        return self * 1.60934
    }

    func inMiles() -> Double {
        return self * 0.621371
    }
}
