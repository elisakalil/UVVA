import Foundation

struct CellarResourcesUIModel {
    var titleText = String(localized: "Your Cellar", bundle: .module)
    var addText = String(localized: "Scan a label", bundle: .module)
    var searchPromptText = String(localized: "Search your cellar", bundle: .module)
    var gridViewText = String(localized: "Grid view", bundle: .module)
    var listViewText = String(localized: "List view", bundle: .module)
    var clearText = String(localized: "Clear", bundle: .module)
    var clearFiltersText = String(localized: "Clear filters", bundle: .module)
    var closeText = String(localized: "Close", bundle: .module)
    var emptyTitleText = String(localized: "Your cellar is empty", bundle: .module)
    var emptyBodyText = String(localized: "Tap + to photograph your first bottle and add it to your cellar.", bundle: .module)
    var noMatchesText = String(localized: "No bottles in your cellar match these filters.", bundle: .module)
    var noteSavedText = String(localized: "Note saved", bundle: .module)
    var bannerTitleText = String(localized: "Every wine you rate moves your map", bundle: .module)
    var bannerBodyText = String(localized: "Bottles marked Not yet wait in your cellar until you taste them.", bundle: .module)
    var searchHintText = String(localized: "Search by wine, grape, region or producer.", bundle: .module)
    var gridIcon = "square.grid.2x2"
    var listIcon = "line.3.horizontal"
    var chipIcon = "chevron.down"
    var checkIcon = "checkmark"
    var closeIcon = "xmark"

    func tag(_ tag: CellarTag) -> String {
        switch tag {
        case .yes: String(localized: "Yes", bundle: .module)
        case .maybe: String(localized: "Maybe", bundle: .module)
        case .no: String(localized: "No", bundle: .module)
        case .notYet: String(localized: "Not yet", bundle: .module)
        }
    }

    func facet(_ facet: CellarFacet) -> String {
        switch facet {
        case .tag: String(localized: "Tag", bundle: .module)
        case .type: String(localized: "Type", bundle: .module)
        case .grape: String(localized: "Grape", bundle: .module)
        case .region: String(localized: "Region", bundle: .module)
        case .producer: String(localized: "Producer", bundle: .module)
        }
    }

    /// "Any grape", under the options of a filter.
    func anyValue(_ facet: CellarFacet) -> String {
        switch facet {
        case .tag: String(localized: "Any tag", bundle: .module)
        case .type: String(localized: "Any type", bundle: .module)
        case .grape: String(localized: "Any grape", bundle: .module)
        case .region: String(localized: "Any region", bundle: .module)
        case .producer: String(localized: "Any producer", bundle: .module)
        }
    }

    func showBottles(_ count: Int) -> String {
        count == 1 ? String(localized: "Show 1 bottle", bundle: .module)
                   : String(localized: "Show \(count) bottles", bundle: .module)
    }

    func notesCount(_ count: Int) -> String {
        count == 1 ? String(localized: "1 note", bundle: .module)
                   : String(localized: "\(count) notes", bundle: .module)
    }

    func noNotes(_ query: String) -> String {
        String(localized: "No notes for “\(query)”", bundle: .module)
    }
}
