import Foundation
import SwiftUI
import DesignSystem

struct WelcomeUIModel {
    var iCloudAvailable: Bool?
    var isSigningIn = false
    var notice: String?
    var signInError = String(localized: "Could not reach Apple. Check your connection and try again.", bundle: .module)
    var canSignIn: Bool { iCloudAvailable == true && !isSigningIn }
    var welcomeLetSFindTheWinesText = String(localized: "Welcome. Let's find the wines you'll love.", bundle: .module)
    var toContinueWithAppleSignInText = String(localized: "To continue with Apple, sign in to iCloud in Settings, then come back.", bundle: .module)
    var uvvaText = String(localized: "UVVA", bundle: .module)
    var appleButton = AppleButtonUIModel()
    var googleButton = GoogleButtonUIModel()
    var agreement = LegalAgreementUIModel()
}
