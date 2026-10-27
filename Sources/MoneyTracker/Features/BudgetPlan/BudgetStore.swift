// BudgetStore.swift
// Purpose: Observable source of truth for the percentage allocation plan with automatic unique colors.

import Foundation
import Observation

@MainActor
@Observable
final class BudgetStore {
    private(set) var buckets: [BudgetBucket] = []

    @ObservationIgnored private let storage: JSONFileStore
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(storage: JSONFileStore = JSONFileStore(fileName: BudgetPlan.fileName)) {
        self.storage = storage
        restore()
    }

    var totalPercentage: Int {
        buckets.reduce(0) { $0 + $1.percentage }
    }

    var unallocatedPercentage: Int {
        100 - totalPercentage
    }

    var isFullyAllocated: Bool { totalPercentage == 100 }
    var isOverAllocated: Bool { totalPercentage > 100 }

    func maximumPercentage(for bucketID: UUID) -> Int {
        guard let bucket = buckets.first(where: { $0.id == bucketID }) else { return 100 }
        return max(0, 100 - (totalPercentage - bucket.percentage))
    }

    func amount(for bucket: BudgetBucket, income: Decimal) -> Decimal {
        (income * Decimal(bucket.percentage) / 100).rounded(scale: 2)
    }

    func unallocatedAmount(income: Decimal) -> Decimal {
        (income * Decimal(unallocatedPercentage) / 100).rounded(scale: 2)
    }

    func isNameUnique(_ name: String, excludingID: UUID? = nil) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return false }
        return !buckets.contains { $0.id != excludingID && $0.trimmedName.lowercased() == trimmed }
    }

    func update(_ bucket: BudgetBucket) {
        guard let index = buckets.firstIndex(where: { $0.id == bucket.id }) else { return }
        buckets[index] = bucket
        scheduleSave()
    }

    func setPercentage(_ percentage: Int, for bucketID: UUID) {
        guard let index = buckets.firstIndex(where: { $0.id == bucketID }) else { return }
        buckets[index].percentage = max(0, min(100, percentage))
        scheduleSave()
    }

    @discardableResult
    func addBucket() -> BudgetBucket {
        let remaining = max(0, unallocatedPercentage)
        let usedColors = Set(buckets.map { $0.colorHex })
        let availableColor = BucketPalette.options.first { !usedColors.contains($0) } ?? BucketPalette.colorHex(at: buckets.count)

        let bucket = BudgetBucket(
            name: "New bucket",
            iconName: "circle.grid.2x2",
            percentage: min(10, remaining),
            colorHex: availableColor
        )
        buckets.append(bucket)
        scheduleSave()
        return bucket
    }

    func add(_ bucket: BudgetBucket) {
        var newBucket = bucket
        let usedColors = Set(buckets.map { $0.colorHex })
        if usedColors.contains(newBucket.colorHex) {
            newBucket.colorHex = BucketPalette.options.first { !usedColors.contains($0) } ?? BucketPalette.colorHex(at: buckets.count)
        }
        buckets.append(newBucket)
        scheduleSave()
    }

    func delete(_ bucket: BudgetBucket) {
        guard buckets.count > 1 else { return }
        buckets.removeAll { $0.id == bucket.id }
        scheduleSave()
    }

    func resetToDefaults() {
        buckets = BudgetBucket.defaults
        scheduleSave()
    }

    func deletePlan() {
        buckets = []
        saveTask?.cancel()
        saveNow()
    }

    private func restore() {
        guard storage.exists else {
            buckets = BudgetBucket.defaults
            saveNow()
            return
        }
        if let plan = storage.load(BudgetPlan.self) {
            buckets = plan.migrated().buckets
        } else {
            buckets = BudgetBucket.defaults
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
        storage.save(BudgetPlan(buckets: buckets))
    }

    func flush() {
        saveTask?.cancel()
        saveNow()
    }
}