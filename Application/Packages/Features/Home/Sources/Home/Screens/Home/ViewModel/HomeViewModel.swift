import Core
import Foundation
import Match
import Observation

/// Reads the stores and builds the Home cards (HOME.md). Friends, lessons, ratings and notifications come with
/// their features; until then the cards that depend on them take their empty variant.
@MainActor @Observable
public final class HomeViewModel {
    private(set) var model: HomeUIModel?
    private(set) var inviteLink: URL?
    /// The wines already in the Cellar, so the day's suggestion shows it is saved.
    private(set) var cellarWineKeys: Set<String> = []

    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let catalog: any CatalogRepository
    private let cellar: any CellarRepository
    private let now: () -> Date
    private let calendar: Calendar

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, catalog: any CatalogRepository,
                cellar: any CellarRepository, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.profiles = profiles
        self.maps = maps
        self.catalog = catalog
        self.cellar = cellar
        self.now = now
        self.calendar = calendar
    }

    /// Loads again whenever something it shows may have changed (a new map, the content import ending).
    public func load() async {
        guard let map = try? await maps.currentMap() else { return }
        let profile = try? await profiles.currentProfile()
        inviteLink = profile?.inviteLink
        cellarWineKeys = (try? await cellar.wineKeys()) ?? []
        let pool = HomeCardsBuilder.dailySuggestionPool
        let wines = (try? await catalog.winesClosest(to: map, limit: pool + HomeCardsBuilder.winesForPalateCount)) ?? []
        let recipes = (try? await catalog.recipes()) ?? []
        let glossary = (try? await catalog.glossary()) ?? []

        // HOME-R06: the wines the day's suggestion is drawn from carry the dish that pairs with them.
        let paired = wines.enumerated().map { index, wine in
            guard index < pool, let recipe = Pairing.recipe(for: wine, user: map, among: recipes) else { return wine }
            var withDish = wine
            withDish.dish = Pairing.dish(from: recipe)
            return withDish
        }
        let state = HomeState(firstName: profile?.firstName ?? "", palateMap: map, friends: [], courses: [],
                              lastRating: nil, ratedWineIDs: [], catalog: paired, glossary: glossary, notifications: [])
        let day = calendar.ordinality(of: .day, in: .era, for: now()) ?? 0
        // The word of the day stays the same all day (HOME-R19, decided 2026-10-31).
        let builder = HomeCardsBuilder(calendar: calendar, pickWordIndex: { count in day % count })
        model = HomeUIModel(cards: builder.build(from: state, now: now()), palateMap: map)
    }

    /// "Add to cellar" on the day's suggestion: the wine goes in as Want to try (CELLAR-R01).
    func addToCellar(_ wine: Wine) async {
        guard !cellarWineKeys.contains(wine.id) else { return }
        // Marked saved only once the store has it, so a failed save leaves the button to try again.
        guard (try? await cellar.addWantToTry(wine)) != nil else { return }
        cellarWineKeys.insert(wine.id)
    }

    var inviteMessage: String {
        String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    }
}
