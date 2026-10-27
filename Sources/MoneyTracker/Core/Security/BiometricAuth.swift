// BiometricAuth.swift
// Purpose: Face ID / Touch ID / Optic ID availability and authentication via
// LocalAuthentication. Each call creates its own LAContext inside a
// nonisolated function so nothing non-Sendable crosses actors.

import Foundation
import LocalAuthentication

enum BiometricKind: Sendable {
    case none
    case faceID
    case touchID
    case opticID

    var title: String {
        switch self {
        case .none: "Biometrics"
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        }
    }

    var iconName: String {
        switch self {
        case .none: "lock"
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        }
    }
}

enum BiometricAuth {
    /// What this device supports and has enrolled.
    static var available: BiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }

    /// Returns true when the user passed the biometric check.
    nonisolated static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
