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
    var notice: String?
    var saveError = String(localized: "Your account could not be saved. Try again.", bundle: .module)
    var counter = "02 / 02"
    var countryChevron = "›"
    var countryAccessibility: String { String(localized: "Country, \(country.name())", bundle: .module) }
    var isSaving: Bool
    var whatIsYourPhoneNumberText = String(localized: "What is your phone number?", bundle: .module)
    var soFriendsWhoHaveYouInText = String(localized: "So friends who have you in their contacts can find you here. We never send you a code or a message.", bundle: .module)
    var skipForNowText = String(localized: "Skip for now", bundle: .module)
    var continueText = String(localized: "Continue", bundle: .module)
    var optionalYouCanStillAddFriendsText = String(localized: "Optional. You can still add friends with your invite link.", bundle: .module)
}
