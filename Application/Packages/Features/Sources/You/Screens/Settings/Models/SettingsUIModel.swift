import Foundation

/// Settings (YOU-R14 to R27).
public struct SettingsUIModel: Equatable {
    var notice: String?
    var isWorking = false
    /// The account could not be deleted: the card at the foot of the screen says so (YOU-R27).
    var deleteFailed = false
    var name: String
    var signedInWith: String
    var phone: String
    var photo: Data?
    var reminder: String
    var mapVisibility: String
    var tables: String
    var certificates: String
    var mapIsPublic: Bool
    var mapPublicNote: String
    var nameText = String(localized: "Name", bundle: .module)
    var signedInWithText = String(localized: "Signed in with", bundle: .module)
    var phoneNumberText = String(localized: "Phone number", bundle: .module)
    var profilePhotoText = String(localized: "Profile photo", bundle: .module)
    var dailyReminderText = String(localized: "Daily reminder", bundle: .module)
    var sharedWithFriendsText = String(localized: "Shared with friends", bundle: .module)
    var myMapText = String(localized: "My Map", bundle: .module)
    var tablesText = String(localized: "Tables", bundle: .module)
    var certificatesText = String(localized: "Certificates", bundle: .module)
    var signOutText = String(localized: "Sign out", bundle: .module)
    var deleteMyAccountText = String(localized: "Delete my account", bundle: .module)
    var whatYouHaveBuiltInText = String(localized: "What you have built in UVVA, ready to share.", bundle: .module)
    var makeChartPublicText = String(localized: "Make chart public", bundle: .module)
    var yourChangesCouldNotBeText = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
    var yourAccountCouldNotBeText = String(localized: "Your account could not be deleted", bundle: .module)
    var nothingWasRemovedText = String(localized: "Nothing was removed. Check your connection and try again.", bundle: .module)
}
