// TransactionKind.swift
// Purpose: Distinguishes money coming in from money going out, and provides the
// labels, icons and default categories used by the tracker UI.

import SwiftUI

enum TransactionKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: "Income"
        case .expense: "Expenses"
        }
    }

    var singularTitle: String {
        switch self {
        case .income: "Income"
        case .expense: "Expense"
        }
    }

    /// Section header glyph.
    var sectionIconName: String {
        switch self {
        case .income: "arrow.down.left"
        case .expense: "arrow.up.right"
        }
    }

    var defaultIcons: [String] {
        switch self {
        case .income:
            ["banknote", "briefcase", "laptopcomputer", "sparkles", "gift", "chart.line.uptrend.xyaxis"]
        case .expense:
            ["cart", "house", "fork.knife", "dumbbell", "bus", "wifi", "creditcard", "bag"]
        }
    }

    var defaultCategory: String {
        defaultIcons[0].replacingOccurrences(of: ".", with: " ").capitalized
    }

    var suggestedCategories: [String] {
        switch self {
        case .income:
            ["Salary", "Freelance", "Side job", "Bonus", "Refund", "Gift"]
        case .expense:
            ["Rent", "Food", "Groceries", "Gym", "Transport", "Subscriptions", "Utilities", "Health"]
        }
    }

    var accent: Color {
        switch self {
        case .income: Color.appAccent
        case .expense: Color.appTextSecondary
        }
    }
}
