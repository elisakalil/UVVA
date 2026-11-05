import Core
import Foundation

public struct EditNameUIModel {
    var name = ""
    var isSaving = false
    var notice: String?
    var isValid: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
    var validationMessage: String {
        isValid ? String(localized: "Nice to meet you", bundle: .module)
            : String(localized: "At least two letters", bundle: .module)
    }
    var saveText = String(localized: "Save", bundle: .module)
    var yourFirstNameText = String(localized: "Your first name", bundle: .module)
    var yourChangesCouldNotBeText = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
}
