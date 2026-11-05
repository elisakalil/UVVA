import Core
import Foundation

public struct EditPhoneUIModel {
    var country = PhoneCountries.defaultCountry()
    var national = ""
    var isSaving = false
    var notice: String?
    var digits: String { national.filter(\.isNumber) }
    var isValid: Bool { digits.isEmpty || PhoneNumber.e164(national: digits, country: country) != nil }
    var saveText = String(localized: "Save", bundle: .module)
    var yourPhoneNumberText = String(localized: "Your phone number", bundle: .module)
    var soFriendsWhoHaveYouText = String(localized: "So friends who have you in their contacts can find you here. Leave it empty to remove it.", bundle: .module)
    var yourChangesCouldNotBeText = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
}
