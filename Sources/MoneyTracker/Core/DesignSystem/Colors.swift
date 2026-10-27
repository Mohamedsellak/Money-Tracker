// Colors.swift
// Purpose: Raw brand palette plus semantic color tokens adhering to the refined fintech design.

import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor(dynamicProvider: { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }))
        #else
        return Color(hex: light)
        #endif
    }
}

#if canImport(UIKit)
import UIKit
private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

extension Color {
    static let appBackground = Color.adaptive(light: 0xF4F5F6, dark: 0x1A1918)
    static let appSurface = Color.adaptive(light: 0xFFFFFF, dark: 0x262524)
    static let appSurfaceElevated = Color.adaptive(light: 0xF4F5F6, dark: 0x464543)
    static let appSurfaceMuted = Color.adaptive(light: 0xECEDEC, dark: 0x32312F)
    static let appCard = Color.adaptive(light: 0xFFFFFF, dark: 0x262524)

    // Hairline: black 8% in light, white 8% in dark
    static let appHairline = Color.adaptive(light: 0x000000, dark: 0xFFFFFF).opacity(0.08)
    static let appBorder = Color.adaptive(light: 0xC7C7C6, dark: 0x464543)

    // Text: textPrimary #2a2928 light / #f4f5f6 dark. textSecondary #6e6d6b light / #a3a2a0 dark.
    static let appTextPrimary = Color.adaptive(light: 0x2A2928, dark: 0xF4F5F6)
    static let appTextSecondary = Color.adaptive(light: 0x6E6D6B, dark: 0xA3A2A0)
    static let appTextMuted = Color.adaptive(light: 0x959493, dark: 0x7A7978)

    // Accent (#bcee29)
    static let appAccent = Color(hex: 0xBCEE29)
    static let appAccentDeep = Color(hex: 0x8DBF0F)
    static let appOnAccent = Color(hex: 0x1F1E1D)

    // Positive & Negative
    static let appPositiveText = Color.adaptive(light: 0x4A6A0E, dark: 0xBCEE29)
    static let appNegative = Color.adaptive(light: 0xD64532, dark: 0xFF7A66)
    static let appNegativeStrong = Color(hex: 0xD64532)

    // Hero "metal" card: deep graphite in both themes with lime highlights.
    static let appInk = Color(hex: 0x1F1E1D)
    static let appInkRaised = Color(hex: 0x2E2D2C)
    static let appOnInk = Color(hex: 0xF4F5F6)
    static let appOnInkMuted = Color(hex: 0xF4F5F6).opacity(0.62)
    static let appInkNegative = Color(hex: 0xFF7A66)

    // Legacy lime hero tokens (toasts, chips)
    static let appHeroSurface = Color(hex: 0xBCEE29)
    static let appHeroText = Color(hex: 0x2A2928)
    static let appHeroMuted = Color(hex: 0x2A2928).opacity(0.7)
    static let appHeroPositive = Color(hex: 0x4A6A0E)
    static let appHeroNegative = Color(hex: 0xD64532)

    // Shadows (light mode only: y 4, blur 16, 6% black)
    static let appShadowLight = Color.black.opacity(0.06)
    static let appShadowMedium = Color.black.opacity(0.08)
}

/// Soft tints for icon tiles, picked deterministically from the icon name so a
/// category always keeps the same colour across launches.
enum CategoryTint {
    static let options: [UInt32] = [
        0xBCEE29, // Lime
        0x7CD3C0, // Mint
        0x9BA9FF, // Periwinkle
        0xFFB86B, // Apricot
        0xE0A9FF, // Orchid
        0x8FC7FF, // Sky
        0xFF8A8A, // Coral
    ]

    private static let fixed: [String: UInt32] = [
        "banknote": 0xBCEE29,
        "briefcase": 0x9BA9FF,
        "laptopcomputer": 0x8FC7FF,
        "sparkles": 0xE0A9FF,
        "gift": 0xFF8A8A,
        "chart.line.uptrend.xyaxis": 0x7CD3C0,
        "house": 0x9BA9FF,
        "cart": 0xFFB86B,
        "fork.knife": 0xFF8A8A,
        "dumbbell": 0x7CD3C0,
        "bus": 0x8FC7FF,
        "wifi": 0xE0A9FF,
        "creditcard": 0xBCEE29,
        "bag": 0xFFB86B,
    ]

    static func hex(for iconName: String) -> UInt32 {
        if let hex = fixed[iconName] { return hex }
        let seed = iconName.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return options[seed % options.count]
    }

    static func color(for iconName: String) -> Color {
        Color(hex: hex(for: iconName))
    }
}

extension LinearGradient {
    /// Lime sheen used on primary buttons and highlights.
    static let accentSheen = LinearGradient(
        colors: [Color(hex: 0xD4FF5C), Color.appAccent, Color(hex: 0xA6DB14)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Graphite gradient of the hero card.
    static let inkSurface = LinearGradient(
        colors: [Color(hex: 0x353432), Color(hex: 0x1F1E1D), Color(hex: 0x151414)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
