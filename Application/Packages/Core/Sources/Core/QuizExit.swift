import Foundation

/// Where the app goes after the Quiz (QUIZ-R25).
public enum QuizExit: Sendable {
    case homeWithTour
    case youMap

    public init(for entry: QuizEntry) {
        switch entry {
        case .firstMap: self = .homeWithTour
        case .redo: self = .youMap
        }
    }
}
