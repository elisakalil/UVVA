import Foundation

/// The profile photo editor (YOU-R14a): the draft on screen and the photo already saved.
public struct EditPhotoUIModel {
    /// The draft: a 512 px square JPEG, or `nil` for no photo.
    var photo: Data?
    var savedPhoto: Data?
    /// The chosen photo is still coming from the library or being washed.
    var isLoading = false
    var isSaving = false
    var notice: String?
    var hasPhoto: Bool { photo != nil }
    var canSave: Bool { photo != savedPhoto && !isLoading && !isSaving }
    var changePhotoText = String(localized: "Change photo", bundle: .module)
    var thePhotoNextToYourText = String(localized: "The photo next to your name. Change it whenever you like.", bundle: .module)
    var choosePhotoText = String(localized: "Choose a photo", bundle: .module)
    var removePhotoText = String(localized: "Remove photo", bundle: .module)
    var saveText = String(localized: "Save", bundle: .module)
    var thatPhotoCouldNotBeText = String(localized: "That photo could not be opened. Try another one.", bundle: .module)
    var yourChangesCouldNotBeText = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
}
