import Core
import Foundation

/// What the wine list keeps between its screens (WINELIST.md), with no side effects: the view model reads and writes
/// it, the builder draws it.
struct WineListState: Equatable {
    var step = WineListStep.checkingCamera
    var isReading = false
    var readingPhoto: Data?
    var pagesRead = 0
    /// The wines of every page read so far, each once.
    private(set) var wines: [WineListWine] = []
    var currency: String?
    var pageMessage: String?

    var palate: PalateMap?
    var friends: [Friend] = []
    var recipes: [Recipe] = []

    var dishes: Set<MenuDish> = []
    /// Nil is no limit.
    var budget: Double?
    var people: Set<String> = []
    var picks: [WineListPick] = []
    var askedID: String?
    var language = WineListLanguage.initial

    var budgetOptions: [Double] { WineListBudget.options(prices: wines.compactMap(\.entry.price)) }

    /// The maps at the table: the user's and the chosen friends'.
    var palates: [PalateMap] {
        [palate].compactMap { $0 } + friends.filter { people.contains($0.id) }.map(\.map)
    }

    /// A page adds the wines the list did not have yet: the same line read twice is one wine.
    mutating func add(_ page: [WineListWine]) {
        let known = Set(wines.map { WineText.tokens($0.entry.name) })
        wines += page.filter { !known.contains(WineText.tokens($0.entry.name)) }
    }

    var asked: WineListPick? { picks.first { $0.id == askedID } ?? picks.first }
}
