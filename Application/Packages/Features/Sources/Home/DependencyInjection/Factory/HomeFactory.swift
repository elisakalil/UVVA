import Core
import Foundation

/// Composition root for Home. Repositories are resolved by the application and injected here.
@MainActor
public struct HomeFactory: HomeFactoryProtocol {
    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let catalog: any CatalogRepository
    private let cellar: any CellarRepository
    private let courses: any CourseCatalog
    private let learning: any LearningRepository
    private let friends: any FriendsRepository
    private let now: () -> Date
    private let calendar: Calendar

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository,
                catalog: any CatalogRepository, cellar: any CellarRepository,
                courses: any CourseCatalog, learning: any LearningRepository, friends: any FriendsRepository,
                now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.profiles = profiles
        self.maps = maps
        self.catalog = catalog
        self.cellar = cellar
        self.courses = courses
        self.learning = learning
        self.friends = friends
        self.now = now
        self.calendar = calendar
    }

    public func makeViewModel(coordinator: any HomeCoordinatorProtocol) -> HomeViewModel {
        let loadPalateState = LoadPalateStateUseCase(maps: maps, cellar: cellar)
        let rankWines = RankWinesUseCase(catalog: catalog)
        return HomeViewModel(
            loadHomeUseCase: LoadHomeUseCase(profiles: profiles, catalog: catalog, loadPalateState: loadPalateState,
                                            rankWines: rankWines, courses: courses, learning: learning,
                                            friends: friends),
            loadPalateStateUseCase: loadPalateState,
            rankWinesUseCase: rankWines,
            addWineToCellarUseCase: AddWineToCellarUseCase(cellar: cellar),
            rateWineUseCase: RateWineUseCase(maps: maps, cellar: cellar, now: now),
            coordinator: coordinator, now: now, calendar: calendar
        )
    }
}
