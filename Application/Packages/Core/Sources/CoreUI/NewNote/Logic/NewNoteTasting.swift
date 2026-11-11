import Foundation

/// The answer to "Have you had this wine?" (CELLAR-R18).
enum NewNoteTasting: Equatable {
    case asking
    /// "Yes · would you drink it again": the verdict, then "Your note" and "Save note".
    case tasted
    /// "Not yet · add to cellar or find it".
    case notYet
}
