//
//  HapticGenerator.swift
//  Birding Local
//
//  Created by Kenny Barone on 12/29/23.
//


import UIKit

class HapticGenerator {
    static let shared = HapticGenerator()

    private init() { }

    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }

    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
}


