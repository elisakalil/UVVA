import Foundation

/// The steps of an import of the bundled content, in the order they run (the Quiz never waits for the lessons).
public enum ContentImportStage: String, Sendable, CaseIterable {
    case quizAndGlossary, recipes, learn
}
