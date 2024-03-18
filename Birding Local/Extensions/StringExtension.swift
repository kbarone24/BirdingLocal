//
//  StringExtension.swift
//  Birding Local
//
//  Created by Kenny Barone on 3/18/24.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
