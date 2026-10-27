// Haptics.swift
// Purpose: Haptic feedback for UI interactions. Generators are created once
// and kept prepared, so the first tap has no latency.

#if canImport(UIKit)
import UIKit
#endif

@MainActor
enum Haptics {
    #if canImport(UIKit)
    private static let impact: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()

    private static let notification: UINotificationFeedbackGenerator = {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }()
    #endif

    static func tap() {
        #if canImport(UIKit)
        impact.impactOccurred()
        impact.prepare()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        notify(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        notify(.warning)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        notify(.error)
        #endif
    }

    #if canImport(UIKit)
    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
        notification.prepare()
    }
    #endif
}
