// IconTile.swift
// Purpose: Rounded-square SF Symbol tile tinted per category, used by rows.

import SwiftUI

struct IconTile: View {
    let iconName: String
    var tint: Color? = nil
    var size: CGFloat = Layout.rowIconSize

    var body: some View {
        let color = tint ?? CategoryTint.color(for: iconName)
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(color.opacity(0.22))
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .strokeBorder(color.opacity(0.35), lineWidth: 1)
            Image(systemName: iconName)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundColor(Color.appTextPrimary)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
