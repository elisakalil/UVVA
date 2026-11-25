import Foundation
import Synchronization

/// The selected language's text overlay, shared by catalog synchronization and reads.
public final class CatalogTextCache: Sendable {
    private struct File: Codable, Sendable {
        var version: String
        var texts: [String: String]
    }

    private let url: URL
    private let cached: Mutex<File?>

    public init(url: URL) {
        self.url = url
        cached = Mutex(try? JSONDecoder().decode(File.self, from: Data(contentsOf: url)))
    }

    var version: String? { cached.withLock { $0?.version } }
    public func translation(for text: String) -> String? {
        cached.withLock { $0?.texts[text] }
    }

    func save(_ texts: [String: String], version: String) throws {
        let file = File(version: version, texts: texts)
        try cached.withLock { current in
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(file).write(to: url, options: .atomic)
            current = file
        }
    }
}
