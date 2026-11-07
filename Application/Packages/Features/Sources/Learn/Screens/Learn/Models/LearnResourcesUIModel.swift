import Foundation

struct LearnResourcesUIModel {
    var viewCertificateText = String(localized: "View certificate", bundle: .module)
    var byRegionText = String(localized: "By region", bundle: .module)
    var byGrapeText = String(localized: "By grape", bundle: .module)
    var thePathText = String(localized: "The path", bundle: .module)
    var searchModulesText = String(localized: "Search modules", bundle: .module)
    var learnText = String(localized: "Learn", bundle: .module)
    var studyWineByRegionByText = String(localized: "Study wine by region, by grape or through a sommelier’s complete curriculum.", bundle: .module)
    var shareWhatYouLearnedText = String(localized: "Share what you learned", bundle: .module)
    var minutesText = String(localized: "Minutes", bundle: .module)
    var xpText = String(localized: "XP", bundle: .module)
    var stepsText = String(localized: "Steps", bundle: .module)
    var byTheEndYouCanText = String(localized: "By the end you can", bundle: .module)
    var leaveTheLessonText = String(localized: "Leave the lesson", bundle: .module)
    var previousScreenText = String(localized: "Previous screen", bundle: .module)
    var backIcon = "chevron.left"
    var continueText = String(localized: "Continue", bundle: .module)

    func noResults(_ query: String) -> String {
        String(localized: "Nothing matches “\(query.trimmingCharacters(in: .whitespaces))”. Try a region, a grape or a country.", bundle: .module)
    }
    func mapAccessibility(_ name: String) -> String { String(localized: "Map of \(name)", bundle: .module) }
    func stepAccessibility(current: Int, total: Int) -> String {
        String(localized: "Step \(current + 1) of \(total)", bundle: .module)
    }
    var tapATermThenItsText = String(localized: "Tap a term, then its match. Tap a matched term to undo.", bundle: .module)
    var correctText = String(localized: "Correct", bundle: .module)
    var yourPickText = String(localized: "Your pick", bundle: .module)
    var whatYouVeLearnedText = String(localized: "What you've learned", bundle: .module)
}
