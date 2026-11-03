import Foundation

/// Settings (YOU-R14 to R27).
struct SettingsUIModel: Equatable {
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
}
