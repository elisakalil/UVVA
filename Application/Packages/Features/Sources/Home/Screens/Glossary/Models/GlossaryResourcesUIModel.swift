import Foundation

struct GlossaryResourcesUIModel {
    var searchPrompt = String(localized: "Search a term", bundle: .module)
    var backToHome = String(localized: "Back to Home", bundle: .module)
    var leaveHint = String(localized: "TAP ANYWHERE TO LEAVE", bundle: .module)
    var clearSearch = String(localized: "Clear search", bundle: .module)
    var clearSelection = String(localized: "Clear selection", bundle: .module)
    var closeDefinition = String(localized: "Close definition", bundle: .module)
    var backgroundAsset = "GlossaryBackground"
    var backSymbol = "chevron.left"
    var searchSymbol = "magnifyingglass"
    var clearSymbol = "xmark"
}
