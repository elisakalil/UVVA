import Core
import Foundation

/// A contact on UVVA who is not a friend yet (FRI-R07). The name is the one in the user's address book.
struct QuickAddSuggestion: Identifiable, Equatable, Sendable {
    var id: String
    var contactName: String
    var map: PalateMap
}
