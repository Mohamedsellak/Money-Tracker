// AuthStore.swift
// Purpose: Observable source of truth for the local account: onboarding state,
// passcode + biometric unlock, auto-lock timing and failed-attempt lockout.

import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    private(set) var profile: UserProfile?
    private(set) var hasPasscode: Bool
    private(set) var isLocked: Bool = false
    private(set) var lockoutUntil: Date?

    private(set) var failedAttempts = 0

    @ObservationIgnored private let storage: JSONFileStore
    @ObservationIgnored let biometricKind = BiometricAuth.available
    @ObservationIgnored private var backgroundedAt: Date?

    static let maxAttempts = 5
    static let lockoutSeconds: TimeInterval = 30

    init(storage: JSONFileStore = JSONFileStore(fileName: UserProfile.fileName)) {
        self.storage = storage
        self.profile = storage.load(UserProfile.self)
        self.hasPasscode = PasscodeVault.isSet
        // Without a profile any leftover Keychain item is stale (e.g. app reinstalled).
        if profile == nil, hasPasscode {
            PasscodeVault.clear()
            hasPasscode = false
        }
        isLocked = profile != nil && hasPasscode
    }

    // MARK: - Derived values

    var isOnboarded: Bool { profile != nil }
    var displayName: String { profile?.name ?? "" }
    var firstName: String { profile?.firstName ?? "" }

    var biometricsEnabled: Bool {
        (profile?.biometricsEnabled ?? false) && biometricKind != .none
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Onboarding

    func createProfile(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile = UserProfile(name: trimmed)
        save()
    }

    func updateName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile?.name = trimmed
        save()
    }

    func setPasscode(_ passcode: String) {
        PasscodeVault.save(passcode)
        hasPasscode = true
    }

    func removePasscode() {
        PasscodeVault.clear()
        hasPasscode = false
        profile?.biometricsEnabled = false
        isLocked = false
        save()
    }

    func setBiometricsEnabled(_ enabled: Bool) {
        profile?.biometricsEnabled = enabled && hasPasscode
        save()
    }

    func setAutoLock(_ autoLock: AutoLock) {
        profile?.autoLock = autoLock
        save()
    }

    // MARK: - Locking

    func lock() {
        guard hasPasscode else { return }
        isLocked = true
    }

    /// Returns true on success. Wrong attempts count toward a temporary lockout.
    func unlock(with passcode: String) -> Bool {
        if let lockoutUntil, lockoutUntil > .now { return false }
        if PasscodeVault.verify(passcode) {
            failedAttempts = 0
            lockoutUntil = nil
            isLocked = false
            return true
        }
        failedAttempts += 1
        if failedAttempts >= Self.maxAttempts {
            failedAttempts = 0
            lockoutUntil = Date.now.addingTimeInterval(Self.lockoutSeconds)
            // Clear the lockout when it expires so the keypad re-enables itself.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(Self.lockoutSeconds))
                self?.lockoutUntil = nil
            }
        }
        return false
    }

    var remainingAttempts: Int { Self.maxAttempts - failedAttempts }

    func verify(_ passcode: String) -> Bool {
        PasscodeVault.verify(passcode)
    }

    func unlockWithBiometrics() async -> Bool {
        guard biometricsEnabled else { return false }
        let success = await BiometricAuth.authenticate(reason: "Unlock your MoneyTracker account")
        if success {
            failedAttempts = 0
            lockoutUntil = nil
            isLocked = false
        }
        return success
    }

    // MARK: - App lifecycle

    func didEnterBackground() {
        backgroundedAt = .now
    }

    func willEnterForeground() {
        guard hasPasscode, let backgroundedAt, let profile else { return }
        if Date.now.timeIntervalSince(backgroundedAt) >= TimeInterval(profile.autoLock.rawValue) {
            isLocked = true
        }
        self.backgroundedAt = nil
    }

    // MARK: - Sign out

    /// Removes the account and its secrets; the app returns to onboarding.
    func signOutAndErase() {
        PasscodeVault.clear()
        storage.deleteFile()
        hasPasscode = false
        profile = nil
        isLocked = false
    }

    private func save() {
        guard let profile else { return }
        storage.save(profile)
    }
}
