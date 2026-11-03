import Foundation

/// The foot of a step: a button, or the feedback with "Continue" once a question is checked.
enum PlayerFooterUIModel: Equatable {
    case button(title: String, isEnabled: Bool)
    case feedback(FeedbackUIModel)
}
