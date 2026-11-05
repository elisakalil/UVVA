import Foundation
import SwiftUI
import DesignSystem

struct NameUIModel {
    var name = ""
    var isValid: Bool { NameValidator.isValid(name) }
    var validationMessage: String {
        isValid ? String(localized: "Nice to meet you", bundle: .module)
            : String(localized: "At least two letters", bundle: .module)
    }
    var counter = "01 / 02"
    var placeholder = "Elisa"
    var andWhatShouldWeCallYouText = String(localized: "And what should we call you?", bundle: .module)
    var yourFirstNameIsEnoughText = String(localized: "Your first name is enough.", bundle: .module)
    var continueText = String(localized: "Continue", bundle: .module)
}
