import Core
import Foundation

/// Complete observable presentation of Home. Domain loading remains in its use case.
public struct HomeUIModel {
    var content: HomeContentUIModel?
    var inviteLink: URL?
    var cellarWineKeys: Set<String> = []
    /// HOME-R24: the verdict of each wine rated since the Quiz.
    var ratedVerdicts: [String: Verdict] = [:]
    var isLoading = true
    /// The Hero and "Wines for your palate" are being read again on a map that moved (HOME-R10c): each shows its
    /// curtain until the new wines are in.
    var isRefreshingMatches = false
    /// The whole Home is being read again after a new note (the matches, "A wine for each strong trait", the map
    /// and the rest): every card shows its curtain until the new cards are in.
    var isReloading = false
    /// The reload follows a note from the Hero: the Home goes back to its top (HOME-R10c).
    var isReturningToTop = false
    /// The line shown for a few seconds after saving or rating a wine (HOME-R24, R28).
    var notice: String?
    var inviteMessage = String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    var resources = HomeResourcesUIModel()
}
