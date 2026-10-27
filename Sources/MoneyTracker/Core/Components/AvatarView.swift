// AvatarView.swift
// Purpose: Circular initials avatar with a lime sheen, used in headers,
// Settings and on the lock screen.

import SwiftUI

struct AvatarView: View {
    let name: String
    var size: CGFloat = 44

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
        let joined = parts.joined().uppercased()
        return joined.isEmpty ? "?" : joined
    }

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient.accentSheen)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundColor(Color.appOnAccent)
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
        .accessibilityHidden(true)
    }
}
