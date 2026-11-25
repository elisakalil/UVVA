import Foundation

public struct WineListUIModel {
    var step = WineListStep.checkingCamera

    // MARK: Camera (WINELIST-R03)
    /// A page is being read.
    var isReading = false
    /// The page held still while it is read.
    var readingPhoto: Data?
    var pagesRead = 0
    var wineCount = 0
    /// How many of them already fit the user's palate (80% or more).
    var fitCount = 0
    var captureTitle = ""
    var captureBody = ""
    var canUseList = false
    /// The last page gave no wine.
    var pageMessage: String?

    // MARK: What's on the table? (WINELIST-R06)
    var wineCountText = ""
    var dishes: [WineListChipUIModel] = []
    var budgets: [WineListChipUIModel] = []
    var people: [WineListChipUIModel] = []

    // MARK: Order this (WINELIST-R07)
    var contextLine = ""
    var hero: WineListPickUIModel?
    var others: [WineListPickUIModel] = []
    /// None of the wines is within the budget: the best of the rest shows, with this said.
    var budgetNote: String?
    var footLine = ""

    // MARK: Say it or show it (WINELIST-R08)
    var ask = WineListAskUIModel()
    var languages: [WineListLanguage] = WineListLanguage.allCases

    var errorText: String?
    var resources = WineListResourcesUIModel()
}
