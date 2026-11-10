import Foundation

/// Complete observable presentation of Home. Domain loading remains in its use case.
public struct HomeUIModel {
    var content: HomeContentUIModel?
    var inviteLink: URL?
    var cellarWineKeys: Set<String> = []
    var isLoading = true
    /// The Hero and "Wines for your palate" are being read again on a map that moved (HOME-R10c): each shows its
    /// curtain until the new wines are in.
    var isRefreshingMatches = false
    /// The line shown for a few seconds after saving or rating a wine (HOME-R24, R28).
    var notice: String?
    var inviteMessage = String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    var resources = HomeResourcesUIModel()
}
