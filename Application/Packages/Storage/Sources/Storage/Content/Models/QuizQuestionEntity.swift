import Foundation
import SwiftData

/// One version of the Quiz question for an axis (QUIZ-R08), in the Content store.
@Model
public final class QuizQuestionEntity {
    #Unique<QuizQuestionEntity>([\.axis, \.version])

    /// The PalateAxis raw value.
    public var axis: String
    /// 1...3
    public var version: Int
    public var prompt: String
    /// One answer per position of the bar, 0...9.
    public var answers: [String]

    init(axis: String, version: Int) {
        self.axis = axis
        self.version = version
        self.prompt = ""
        self.answers = []
    }
}
