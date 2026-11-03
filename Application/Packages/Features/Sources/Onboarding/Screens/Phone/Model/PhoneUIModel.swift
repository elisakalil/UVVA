import Core
import Foundation

/// Phone (ONB-R03 to R07, R35).
struct PhoneUIModel: Equatable {
    var country: PhoneCountry
    var dialCode: String
    /// The digits typed, in groups of three; the example when empty.
    var number: String
    var isEmpty: Bool
    var canContinue: Bool
    var isSaving: Bool
}
