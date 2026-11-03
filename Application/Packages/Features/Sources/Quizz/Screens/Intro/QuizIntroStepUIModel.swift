import Foundation

struct QuizIntroStepUIModel: Equatable, Identifiable {
    var number: String
    var title: String
    var body: String
    var id: String { number }
}
