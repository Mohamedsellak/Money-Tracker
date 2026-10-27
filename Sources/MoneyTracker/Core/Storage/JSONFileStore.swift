// JSONFileStore.swift
// Purpose: Plain JSON persistence in the app's Documents directory using
// Codable and atomic writes. One file per feature, no database, no macros.

import Foundation

struct JSONFileStore: Sendable {
    let fileName: String
    let directory: URL

    init(fileName: String, directory: URL? = nil) {
        self.fileName = fileName
        self.directory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var url: URL {
        directory.appendingPathComponent(fileName, isDirectory: false)
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// Loads and decodes the document, or returns nil when the file is missing
    /// or unreadable (a fresh install must never crash).
    func load<Document: Storable>(_ type: Document.Type) -> Document? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Document.self, from: data)
        } catch {
            #if DEBUG
            print("[JSONFileStore] failed to decode \(fileName): \(error)")
            #endif
            return nil
        }
    }

    /// Encodes and writes the document atomically (no half-written files).
    func save<Document: Storable>(_ document: Document) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(document)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
        } catch {
            #if DEBUG
            print("[JSONFileStore] failed to save \(fileName): \(error)")
            #endif
        }
    }

    func deleteFile() {
        try? FileManager.default.removeItem(at: url)
    }
}
