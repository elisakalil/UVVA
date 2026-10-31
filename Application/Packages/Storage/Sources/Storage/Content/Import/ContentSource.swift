import Foundation

/// Where the packed content files are: the app bundle in the app, a temporary folder in the tests.
public struct ContentSource: Sendable {
    public var manifest: URL
    public var wines: URL
    public var recipes: URL
    public var learn: URL
    public var glossary: URL
    public var quiz: URL

    /// The files written by pack_content.py, all in one folder.
    public init(directory: URL) {
        manifest = directory.appending(path: "manifest.json")
        wines = directory.appending(path: "wines.json")
        recipes = directory.appending(path: "recipes.json")
        learn = directory.appending(path: "learn.json")
        glossary = directory.appending(path: "glossary.json")
        quiz = directory.appending(path: "quiz.json")
    }

    /// The files copied into a bundle. Nil if the manifest is missing.
    public init?(bundle: Bundle) {
        guard let manifest = bundle.url(forResource: "manifest", withExtension: "json") else { return nil }
        self.init(directory: manifest.deletingLastPathComponent())
    }
}
