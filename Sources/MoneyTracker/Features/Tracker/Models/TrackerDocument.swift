// TrackerDocument.swift
// Purpose: The versioned on-disk shape of the tracker feature. Bumping the
// version lets a future release migrate old files.

import Foundation

struct TrackerDocument: Storable {
    static let fileName = "tracker.json"
    static let currentVersion = 1

    var version: Int
    var items: [TransactionItem]

    init(version: Int = TrackerDocument.currentVersion, items: [TransactionItem]) {
        self.version = version
        self.items = items
    }

    /// Hook for future schema changes.
    func migrated() -> TrackerDocument {
        var copy = self
        copy.version = TrackerDocument.currentVersion
        return copy
    }
}
