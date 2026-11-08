import Foundation

/// What Quick add shows (FRI-R07, R07a).
enum QuickAddState: Equatable {
    /// Contacts were never asked for: a button shows the iOS prompt.
    case askAccess
    /// iOS no longer asks: a button opens the Settings.
    case openSettings
    /// Access given, and no contact on UVVA to suggest.
    case noSuggestions
    case suggestions([QuickAddRowUIModel])
}
