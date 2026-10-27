// Storable.swift
// Purpose: Contract for every persisted document: Codable, Sendable, versioned,
// and aware of its own JSON file name.

import Foundation

protocol Storable: Codable, Sendable {
    /// File name inside the Documents directory, e.g. "tracker.json".
    static var fileName: String { get }
    /// Schema version written to disk.
    static var currentVersion: Int { get }
    /// Version of the currently loaded instance.
    var version: Int { get }
}
