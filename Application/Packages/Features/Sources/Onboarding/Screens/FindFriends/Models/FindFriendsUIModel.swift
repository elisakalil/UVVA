import Foundation
import SwiftUI
import DesignSystem

struct FindFriendsUIModel {
    var isAsking = false
    var illustration: Image { UVVAIllustration.grape(4) }
    var privacyIcon = "lock"
    var findFriendsText = String(localized: "Find friends", bundle: .module)
    var continueText = String(localized: "Continue", bundle: .module)
    var addYourClosestFriendsToStartText = String(localized: "Add your closest friends to start comparing palates.", bundle: .module)
    var uvvaIsBetterWithFriendsAddText = String(localized: "UVVA is better with friends. Add them now and, once they accept, you will see where your palates meet and what to open together.", bundle: .module)
    var weWillNeverDoAnythingCreepyText = String(localized: "We will never do anything creepy like spam or auto-add your friends.", bundle: .module)
}
