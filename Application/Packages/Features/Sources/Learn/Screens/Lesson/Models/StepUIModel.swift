import Foundation

/// The body of the step on screen.
enum StepUIModel: Equatable {
    case concept(title: String, body: String, highlight: String?)
    case tip(body: String)
    case choice(ChoiceUIModel)
    case fillBlank(FillBlankUIModel)
    case ordering(OrderingUIModel)
    case matchPairs(MatchPairsUIModel)
    case summary(LessonSummaryUIModel)
}
