import Foundation

/// The steps of an import, in the order they run (the Quiz never waits for the wines).
public enum ContentImportStage: String, Sendable, CaseIterable {
    case quizAndGlossary, recipes, learn, wines
}
