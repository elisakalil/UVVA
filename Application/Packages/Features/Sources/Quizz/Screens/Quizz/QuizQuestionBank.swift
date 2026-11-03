import Core
import Foundation

/// The 24 questions by axis and version.
struct QuizQuestionBank: Sendable {
    private let questions: [PalateAxis: [Int: QuizQuestion]]

    init(_ list: [QuizQuestion]) {
        var questions: [PalateAxis: [Int: QuizQuestion]] = [:]
        for question in list { questions[question.axis, default: [:]][question.version] = question }
        self.questions = questions
    }

    /// True when every axis has its three versions with ten answers each.
    var isComplete: Bool {
        QuizFlow.order.allSatisfy { axis in
            (1...QuizFlow.versionCount).allSatisfy { questions[axis]?[$0]?.answers.count == 10 }
        }
    }

    func question(_ axis: PalateAxis, version: Int) -> QuizQuestion? {
        questions[axis]?[version]
    }
}
