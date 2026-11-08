import Foundation

public struct CellarUIModel {
    var viewMode: CellarViewMode = .grid
    var state: CellarListState = .empty
    var items: [CellarItemUIModel] = []
    var chips: [CellarChipUIModel] = []
    /// The filters are faded and do nothing while the Cellar is empty (CELLAR-R05).
    var areFiltersEnabled = false
    var isFiltered = false
    var filterSheet: CellarFilterSheetUIModel?
    var isBannerVisible = false
    var query = ""
    /// The search has words: its results take the place of the Cellar.
    var isSearching = false
    var searchCount = ""
    var searchResults: [CellarSearchResultUIModel] = []
    var noResultsText = ""
    var resources = CellarResourcesUIModel()
}
