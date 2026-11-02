import Foundation

/// manifest.json, written by pack_content.py.
public struct ContentManifest: Decodable, Sendable {
    /// Hash of the packed files. A new value means new content to import.
    public var version: String
    public var counts: [String: Int]
}
