import Core
import Foundation

/// One course in a Learn list, and what it shows when open (LEARN-R07, R09, R10a, R11).
struct CourseRowUIModel: Identifiable, Equatable {
    var id: String
    var title: String
    /// "6 lessons · 31 min · 90 XP"
    var meta: String
    var state: CourseState
    var isOpen: Bool
    var about: String
    /// Region only: the grapes it grows.
    var grapes: [String]
    /// "Go to the module", "Continue where you left off" or "Review the module".
    var cta: String
    var hasCertificate: Bool
}
