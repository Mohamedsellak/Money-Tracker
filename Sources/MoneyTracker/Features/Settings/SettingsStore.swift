// SettingsStore.swift
// Purpose: Observable store for app-wide settings persisted via JSON file.

import Foundation
import Observation

struct SettingsDocument: Codable, Sendable, Storable {
    static let fileName = "settings.json"
    static let currentVersion = 2

    var version: Int = SettingsDocument.currentVersion
    var theme: String = "system"
    var currencyCode: String = "EUR"
    var isFirstLaunch: Bool = true
    /// v2: blur amounts on screen (for use in public).
    var hideBalances: Bool = false

    init() {}

    /// Tolerant decoding so files written by older versions keep their values.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? "system"
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "EUR"
        isFirstLaunch = try container.decodeIfPresent(Bool.self, forKey: .isFirstLaunch) ?? true
        hideBalances = try container.decodeIfPresent(Bool.self, forKey: .hideBalances) ?? false
    }

    func migrated() -> SettingsDocument {
        var copy = self
        copy.version = SettingsDocument.currentVersion
        return copy
    }
}

@MainActor
@Observable
final class SettingsStore {
    private let storage: JSONFileStore
    private(set) var document: SettingsDocument

    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(storage: JSONFileStore = JSONFileStore(fileName: SettingsDocument.fileName)) {
        self.storage = storage
        self.document = SettingsDocument()
        restore()
    }

    var theme: AppTheme {
        get {
            AppTheme(rawValue: document.theme) ?? .system
        }
        set {
            document.theme = newValue.rawValue
            scheduleSave()
        }
    }

    var currencyCode: String {
        get { document.currencyCode }
        set {
            document.currencyCode = newValue
            scheduleSave()
        }
    }

    var isFirstLaunch: Bool {
        get { document.isFirstLaunch }
        set {
            document.isFirstLaunch = newValue
            scheduleSave()
        }
    }

    var hideBalances: Bool {
        get { document.hideBalances }
        set {
            document.hideBalances = newValue
            scheduleSave()
        }
    }

    static let availableCurrencies: [(code: String, name: String, icon: String)] = [
        ("EUR", "Euro", "eurosign"),
        ("USD", "US Dollar", "dollarsign"),
        ("GBP", "British Pound", "sterlingsign"),
        ("JPY", "Japanese Yen", "yensign"),
        ("CHF", "Swiss Franc", "francsign"),
        ("CAD", "Canadian Dollar", "dollarsign"),
        ("AUD", "Australian Dollar", "dollarsign"),
    ]

    var currencyName: String {
        Self.availableCurrencies.first { $0.code == currencyCode }?.name ?? currencyCode
    }

    func resetAllData() {
        JSONFileStore(fileName: TrackerDocument.fileName).deleteFile()
        JSONFileStore(fileName: BudgetPlan.fileName).deleteFile()
        storage.deleteFile()
        document = SettingsDocument()
        scheduleSave()
    }

    private func restore() {
        if let loaded = storage.load(SettingsDocument.self) {
            document = loaded.migrated()
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
        storage.save(document)
    }

    func flush() {
        saveTask?.cancel()
        saveNow()
    }
}
