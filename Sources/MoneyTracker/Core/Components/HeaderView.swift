// HeaderView.swift
// Purpose: Screen header with an optional small eyebrow line above a large
// rounded title, and an optional 44pt circular action button.

import SwiftUI

struct HeaderView: View {
    let title: String
    let eyebrow: String?
    let actionIcon: String?
    let actionAccessibilityLabel: String?
    let action: (() -> Void)?

    init(
        title: String,
        eyebrow: String? = nil,
        actionIcon: String? = nil,
        actionAccessibilityLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.eyebrow = eyebrow
        self.actionIcon = actionIcon
        self.actionAccessibilityLabel = actionAccessibilityLabel
        self.action = action
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(AppFont.eyebrow)
                        .tracking(1.2)
                        .foregroundColor(Color.appTextSecondary)
                }
                Text(title)
                    .font(AppFont.title)
                    .foregroundColor(Color.appTextPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            if let actionIcon, let action {
                CircleIconButton(
                    iconName: actionIcon,
                    accessibilityLabel: actionAccessibilityLabel ?? "Action",
                    action: action
                )
            }
        }
        .horizontalMargin()
        .padding(.top, 8)
        .padding(.bottom, Spacing.md)
    }
}

/// 44pt round button on a card surface.
struct CircleIconButton: View {
    let iconName: String
    let accessibilityLabel: String
    var isAccent: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isAccent ? Color.appOnAccent : Color.appTextPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isAccent ? AnyShapeStyle(LinearGradient.accentSheen) : AnyShapeStyle(Color.appSurface))
                        .shadow(color: isAccent ? Color.appAccent.opacity(0.4) : Color.appShadowLight, radius: 8, x: 0, y: 3)
                )
                .overlay(Circle().strokeBorder(Color.appHairline, lineWidth: 1))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(accessibilityLabel)
    }
}
