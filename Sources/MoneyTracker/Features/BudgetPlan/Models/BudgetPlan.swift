// BudgetPlan.swift
// Purpose: Versioned on-disk document for the budget feature (one JSON file).

import Foundation

struct BudgetPlan: Storable {
    static let fileName = "budget.json"
    static let currentVersion = 1

    var version: Int
    var buckets: [BudgetBucket]

    init(version: Int = BudgetPlan.currentVersion, buckets: [BudgetBucket]) {
        self.version = version
        self.buckets = buckets
    }

    func migrated() -> BudgetPlan {
        var copy = self
        copy.version = BudgetPlan.currentVersion
        return copy
    }
}
