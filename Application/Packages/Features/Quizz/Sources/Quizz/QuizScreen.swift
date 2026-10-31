import Foundation

/// The screen on display, with its model.
enum QuizScreen: Equatable {
    case loading
    case intro(QuizIntroUIModel)
    case reading(QuizReadingUIModel)
    case result(QuizResultUIModel)
    case share(QuizShareUIModel)
}
