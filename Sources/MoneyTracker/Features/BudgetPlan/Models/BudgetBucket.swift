// BudgetBucket.swift
// Purpose: One allocation slice of the budget plan with distinct automatic palette colors.

import SwiftUI

struct BudgetBucket: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var iconName: String
    var percentage: Int
    var colorHex: UInt32
    var linkedCategory: String?

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        percentage: Int,
        colorHex: UInt32,
        linkedCategory: String? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.percentage = max(0, min(100, percentage))
        self.colorHex = colorHex
        self.linkedCategory = linkedCategory
    }

    var color: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor(dynamicProvider: { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let hexToUse = (colorHex == 0x464543 && isDark) ? 0xE2E3E2 : colorHex
            let red = CGFloat((hexToUse >> 16) & 0xFF) / 255
            let green = CGFloat((hexToUse >> 8) & 0xFF) / 255
            let blue = CGFloat(hexToUse & 0xFF) / 255
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        }))
        #else
        return Color(hex: colorHex)
        #endif
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var fraction: Double { Double(percentage) / 100 }
}

enum BucketPalette {
    /// Distinct palette of vibrant fintech colors
    static let options: [UInt32] = [
        0xBCEE29, // Lime
        0x5D7D12, // Deep green
        0x7CD3C0, // Mint
        0x9BA9FF, // Periwinkle
        0xFFB86B, // Apricot
        0xE0A9FF, // Orchid
        0x8FC7FF, // Sky
        0xFF8A8A, // Coral
        0x464543, // Dark grey
        0x959493, // Mid grey
    ]

    static func colorHex(at index: Int) -> UInt32 {
        options[index % options.count]
    }
}

extension BudgetBucket {
    static var defaults: [BudgetBucket] {
        [
            BudgetBucket(name: "Essentials", iconName: "house", percentage: 60, colorHex: 0xBCEE29, linkedCategory: "Rent"),
            BudgetBucket(name: "Personal", iconName: "sparkles", percentage: 10, colorHex: 0x5D7D12),
            BudgetBucket(name: "Investing", iconName: "chart.line.uptrend.xyaxis", percentage: 10, colorHex: 0x7CD3C0),
            BudgetBucket(name: "Savings", iconName: "banknote", percentage: 10, colorHex: 0x9BA9FF),
            BudgetBucket(name: "Debt payoff", iconName: "creditcard", percentage: 10, colorHex: 0xFFB86B),
        ]
    }
}