// TrackerStore.swift
// Purpose: Observable source of truth for all income and expense items. Totals
// are derived (never stored), persistence is debounced JSON.

import Foundation
import Observation

@MainActor
@Observable
final class TrackerStore {
    /// All entries, in insertion order.
    private(set) var items: [TransactionItem] = []

    @ObservationIgnored private let storage: JSONFileStore
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(storage: JSONFileStore = JSONFileStore(fileName: TrackerDocument.fileName)) {
        self.storage = storage
        restore()
    }

    // MARK: - Derived values

    func items(for kind: TransactionKind) -> [TransactionItem] {
        items.filter { $0.kind == kind }
    }

    func total(for kind: TransactionKind) -> Decimal {
        items
            .filter { $0.kind == kind }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var totalIncome: Decimal { total(for: .income) }
    var totalExpenses: Decimal { total(for: .expense) }
    var balance: Decimal { totalIncome - totalExpenses }
    var isEmpty: Bool { items.isEmpty }

    /// Spending grouped by category, used by the budget comparison.
    func categoryTotals(for kind: TransactionKind = .expense) -> [String: Decimal] {
        var totals: [String: Decimal] = [:]
        for item in items(for: kind) {
            let key = item.displayCategory ?? "Uncategorised"
            totals[key, default: .zero] += item.amount
        }
        return totals
    }

    /// Spending for one category, case-insensitive.
    func total(forCategory category: String) -> Decimal {
        let target = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return items(for: .expense)
            .filter { ($0.displayCategory ?? "").lowercased() == target }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    // MARK: - Mutations

    func add(_ item: TransactionItem) {
        items.append(item)
        scheduleSave()
    }

    func update(_ item: TransactionItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        scheduleSave()
    }

    func delete(_ item: TransactionItem) {
        items.removeAll { $0.id == item.id }
        scheduleSave()
    }

    /// Re-inserts a deleted item at its old position (used by Undo).
    func restore(_ item: TransactionItem, at index: Int) {
        items.insert(item, at: min(max(0, index), items.count))
        scheduleSave()
    }

    func index(of item: TransactionItem) -> Int? {
        items.firstIndex { $0.id == item.id }
    }

    /// Largest single expense, for the insights row.
    var topExpense: TransactionItem? {
        items(for: .expense).max { $0.amount < $1.amount }
    }

    /// Share of income left after expenses, 0...1 (nil without income).
    var savingsRate: Double? {
        guard totalIncome > 0 else { return nil }
        return max(0, min(1, (balance / totalIncome).doubleValue))
    }

    func deleteAll() {
        items.removeAll()
        saveTask?.cancel()
        saveNow()
    }

    /// Restores the first-launch sample entries (used by Settings).
    func reloadSamples() {
        items = TransactionItem.samples
        scheduleSave()
    }

    // MARK: - Persistence

    private func restore() {
        guard storage.exists else {
            items = TransactionItem.samples
            saveNow()
            return
        }
        if let document = storage.load(TrackerDocument.self) {
            items = document.migrated().items
        } else {
            items = TransactionItem.samples
            saveNow()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    private func saveNow() {
        let document = TrackerDocument(items: items)
        storage.save(document)
    }

    /// Writes pending changes immediately (called when the app backgrounds).
    func flush() {
        saveTask?.cancel()
        saveNow()
    }
}