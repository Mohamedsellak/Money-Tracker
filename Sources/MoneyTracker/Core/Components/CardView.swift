// CardView.swift
// Purpose: A reusable container for the top summary card and any other
// stand-out section. Uses the dark hero surface (#464543) with rounded corners.

import SwiftUI

struct CardView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.appHeroSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? Color.appBorder.opacity(0.25) : Color.appAccent.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                radius: 24,
                x: 0,
                y: 16
            )
    }
}
