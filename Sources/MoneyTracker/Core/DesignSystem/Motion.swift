// Motion.swift
// Purpose: Shared animation tokens so every transition feels like one product.
// Views pass `reduceMotion` to get a calm cross-fade instead of movement.

import SwiftUI

enum Motion {
    /// Taps, toggles, chips.
    static let snappy = Animation.spring(response: 0.24, dampingFraction: 0.86)
    /// Cards, sheets, tab changes.
    static let smooth = Animation.spring(response: 0.32, dampingFraction: 0.88)
    /// Hero reveals and onboarding.
    static let gentle = Animation.spring(response: 0.45, dampingFraction: 0.9)
    /// Number roll-ups.
    static let numeric = Animation.spring(response: 0.38, dampingFraction: 0.9)

    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : animation
    }
}

/// Fades and lifts content in when it appears, staggered by `index`.
struct AppearLift: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 8)
            .onAppear {
                withAnimation(Motion.respecting(reduceMotion, Motion.smooth).delay(Double(index) * 0.03)) {
                    isVisible = true
                }
            }
    }
}

/// Horizontal shake used for a wrong passcode.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 10
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * 4), y: 0))
    }
}

extension View {
    func appearLift(_ index: Int = 0) -> some View {
        modifier(AppearLift(index: index))
    }

    func shake(_ trigger: CGFloat) -> some View {
        modifier(ShakeEffect(animatableData: trigger))
    }
}
