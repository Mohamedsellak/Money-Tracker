// View+Modifiers.swift
// Purpose: Reusable visual treatments for the fintech look.

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.respecting(reduceMotion, Motion.snappy), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

struct SurfaceCard: ViewModifier {
    var cornerRadius: CGFloat = Radius.card
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        // The shadow sits on the background shape only, so text inside the
        // card is not shadowed glyph by glyph (much cheaper to render).
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.appSurface)
                    .shadow(
                        color: colorScheme == .dark ? .clear : Color.black.opacity(0.06),
                        radius: 14,
                        x: 0,
                        y: 6
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.appHairline, lineWidth: colorScheme == .dark ? 1 : 0.5)
            )
    }
}

/// Deep graphite "metal card" with a lime glow, used for the balance hero.
/// Glows are radial gradients rather than blurred circles.
struct InkCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    shape.fill(LinearGradient.inkSurface)
                    shape.fill(
                        RadialGradient(
                            colors: [Color.appAccent.opacity(0.38), Color.appAccent.opacity(0)],
                            center: UnitPoint(x: 0.95, y: -0.05),
                            startRadius: 0,
                            endRadius: 260
                        )
                    )
                    shape.fill(
                        RadialGradient(
                            colors: [Color(hex: 0x7CD3C0).opacity(0.16), Color(hex: 0x7CD3C0).opacity(0)],
                            center: UnitPoint(x: 0.1, y: 1.05),
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                }
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.2), radius: 22, x: 0, y: 14)
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
    }
}

/// Applies the hide-balances mask only when needed, so visible amounts carry
/// no blur filter at all.
private struct MaskedAmount: ViewModifier {
    let isHidden: Bool

    func body(content: Content) -> some View {
        if isHidden {
            content
                .blur(radius: 9)
                .opacity(0.75)
                .accessibilityHidden(true)
        } else {
            content
        }
    }
}

extension View {
    func surfaceCard(cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(SurfaceCard(cornerRadius: cornerRadius))
    }

    func inkCard() -> some View {
        modifier(InkCard())
    }

    func cardStyle() -> some View {
        surfaceCard()
    }

    func horizontalMargin() -> some View {
        padding(.horizontal, Spacing.horizontalMargin)
    }

    func screenBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }

    /// Masks content when the user turns on "hide balances".
    func masked(_ isHidden: Bool) -> some View {
        modifier(MaskedAmount(isHidden: isHidden))
    }
}
