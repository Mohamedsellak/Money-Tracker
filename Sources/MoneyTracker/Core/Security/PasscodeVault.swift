// PasscodeVault.swift
// Purpose: Stores the app passcode as a salted SHA-256 hash in the Keychain and
// verifies attempts in constant time. The plain passcode is never persisted.

import CryptoKit
import Foundation

enum PasscodeVault {
    static let length = 6

    private static let hashKey = "passcode.hash"
    private static let saltKey = "passcode.salt"

    static var isSet: Bool {
        KeychainStore.data(for: hashKey) != nil
    }

    static func save(_ passcode: String) {
        var salt = Data(count: 16)
        let status = salt.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, 16, buffer.baseAddress!)
        }
        if status != errSecSuccess {
            salt = Data(UUID().uuidString.utf8)
        }
        KeychainStore.set(salt, for: saltKey)
        KeychainStore.set(digest(passcode, salt: salt), for: hashKey)
    }

    static func verify(_ passcode: String) -> Bool {
        guard
            let salt = KeychainStore.data(for: saltKey),
            let stored = KeychainStore.data(for: hashKey)
        else { return false }
        let candidate = digest(passcode, salt: salt)
        guard candidate.count == stored.count else { return false }
        // Constant-time comparison.
        return zip(candidate, stored).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    static func clear() {
        KeychainStore.delete(hashKey)
        KeychainStore.delete(saltKey)
    }

    private static func digest(_ passcode: String, salt: Data) -> Data {
        var input = salt
        input.append(Data(passcode.utf8))
        return Data(SHA256.hash(data: input))
    }
}
