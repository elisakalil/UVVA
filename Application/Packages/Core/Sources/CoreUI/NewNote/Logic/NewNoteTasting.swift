import Foundation

/// The answer to "Have you had this wine?", or to "Rate it again?" for a wine rated before (CELLAR-R18, R14a).
enum NewNoteTasting: Equatable {
    case asking
    /// "Yes · would you drink it again": the verdict, then "Your note" and "Save note". For a wine rated before,
    /// "Rate it again? · Yes": a new verdict.
    case tasted
    /// "Not yet · add to cellar or find it".
    case notYet
    /// "Rate it again? · No": the verdict the wine was rated with before stays.
    case keptRating
}
