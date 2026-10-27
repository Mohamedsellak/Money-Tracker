// TransactionItem.swift
// Purpose: A single income source or expense entry. Money is stored as Decimal
// so totals never drift the way Double math does.

import Foundation

struct TransactionItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var amount: Decimal
    var kind: TransactionKind
    var iconName: String
    /// Optional free-form category, e.g. "Housing" or "Fun".
    var category: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        kind: TransactionKind,
        iconName: String,
        category: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.kind = kind
        self.iconName = iconName
        self.category = category
        self.createdAt = createdAt
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Category shown under the name, trimmed and nil when empty.
    var displayCategory: String? {
        guard let category else { return nil }
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension TransactionItem {
    /// Sample data shipped on first launch. Fully deletable by the user.
    static var samples: [TransactionItem] {
        [
            TransactionItem(name: "Salary", amount: 2_400, kind: .income, iconName: "banknote", category: "Salary"),
            TransactionItem(name: "Freelance project", amount: 450, kind: .income, iconName: "laptopcomputer", category: "Freelance"),
            TransactionItem(name: "Weekend side job", amount: 180, kind: .income, iconName: "sparkles", category: "Side job"),
            TransactionItem(name: "Rent", amount: 950, kind: .expense, iconName: "house", category: "Rent"),
            TransactionItem(name: "Groceries", amount: 320, kind: .expense, iconName: "cart", category: "Groceries"),
            TransactionItem(name: "Subscriptions", amount: 24.99, kind: .expense, iconName: "wifi", category: "Subscriptions"),
            TransactionItem(name: "Gym", amount: 39, kind: .expense, iconName: "dumbbell", category: "Gym"),
            TransactionItem(name: "Transport", amount: 75, kind: .expense, iconName: "bus", category: "Transport"),
        ]
    }
}
