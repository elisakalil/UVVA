import Foundation

/// Where the packed content files are: the app bundle in the app, a temporary folder in the tests.
public struct ContentSource: Sendable {
    public var manifest: URL
    public var recipes: URL
    public var learn: URL
    public var glossary: URL
    public var quiz: URL

    /// The files written by pack_content.py, all in one folder.
    public init(directory: URL, language: String? = nil) {
        manifest = directory.appending(path: "manifest.json")
        recipes = directory.appending(path: "recipes.json")
        learn = directory.appending(path: "learn.json")
        glossary = directory.appending(path: "glossary.json")
        quiz = directory.appending(path: "quiz.json")

        if let language {
            let localizedManifest = directory.appending(path: "manifest-\(language).json")
            let localizedLearn = directory.appending(path: "learn-\(language).json")
            let localizedGlossary = directory.appending(path: "glossary-\(language).json")
            let localizedRecipes = directory.appending(path: "recipes-\(language).json")
            if [localizedManifest, localizedLearn, localizedGlossary, localizedRecipes].allSatisfy({
                FileManager.default.fileExists(atPath: $0.path)
            }) {
                manifest = localizedManifest
                learn = localizedLearn
                recipes = localizedRecipes
                glossary = localizedGlossary
            }
        }
    }

    /// The files copied into a bundle. Nil if the manifest is missing.
    public init?(bundle: Bundle) {
        guard let manifest = bundle.url(forResource: "manifest", withExtension: "json") else { return nil }
        self.init(directory: manifest.deletingLastPathComponent(), language: bundle.preferredLocalizations.first)
    }
}
