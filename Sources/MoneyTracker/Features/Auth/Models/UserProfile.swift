// UserProfile.swift
// Purpose: The local account: display name and security preferences. Stored as
// JSON like the other features; the passcode itself lives in the Keychain.

import Foundation

enum AutoLock: Int, Codable, CaseIterable, Identifiable, Sendable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .immediately: "Immediately"
        case .oneMinute: "After 1 minute"
        case .fiveMinutes: "After 5 minutes"
        case .fifteenMinutes: "After 15 minutes"
        }
    }
}

struct UserProfile: Storable {
    static let fileName = "profile.json"
    static let currentVersion = 1

    var version: Int
    var name: String
    var createdAt: Date
    var biometricsEnabled: Bool
    var autoLock: AutoLock

    init(
        version: Int = UserProfile.currentVersion,
        name: String,
        createdAt: Date = .now,
        biometricsEnabled: Bool = false,
        autoLock: AutoLock = .oneMinute
    ) {
        self.version = version
        self.name = name
        self.createdAt = createdAt
        self.biometricsEnabled = biometricsEnabled
        self.autoLock = autoLock
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}
