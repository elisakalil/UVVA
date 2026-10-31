import Core

/// Every axis with three versions and ten answers ("acidity v2 #6").
struct QuestionRepositoryStub: QuizQuestionRepository {
    func questions() async throws -> [QuizQuestion] {
        PalateAxis.allCases.flatMap { axis in
            (1...3).map { version in
                QuizQuestion(axis: axis, version: version, prompt: "\(axis.rawValue) v\(version)?",
                             answers: (0...9).map { "\(axis.rawValue) v\(version) #\($0)" })
            }
        }
    }
}
