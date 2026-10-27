// AuroraBackground.swift
// Purpose: Slowly drifting soft light blobs behind onboarding and the lock
// screen. Blobs are radial gradients (no blur filter) moved by one repeating
// animation, so Core Animation interpolates them without re-running the body.
// Static when Reduce Motion is on.

import SwiftUI

struct AuroraBackground: View {
    var base: Color = .appInk
    var intensity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let shift: CGFloat = drift ? 1 : -1
            ZStack {
                base

                Blob(color: Color.appAccent.opacity(0.5 * intensity), diameter: size.width * 1.6)
                    .offset(x: size.width * (0.28 + 0.08 * shift), y: -size.height * (0.30 + 0.04 * shift))

                Blob(color: Color(hex: 0x7CD3C0).opacity(0.32 * intensity), diameter: size.width * 1.3)
                    .offset(x: -size.width * (0.32 - 0.07 * shift), y: -size.height * (0.05 - 0.05 * shift))

                Blob(color: Color(hex: 0x9BA9FF).opacity(0.22 * intensity), diameter: size.width * 1.4)
                    .offset(x: size.width * 0.16 * shift, y: size.height * (0.38 + 0.03 * shift))
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .drawingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

/// A soft glow: a radial gradient fading to clear looks like a blurred circle
/// but costs a single gradient fill instead of a blur pass.
private struct Blob: View {
    let color: Color
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [color, color.opacity(0)], center: .center, startRadius: 0, endRadius: diameter / 2))
            .frame(width: diameter, height: diameter)
    }
}
