import Core
import DesignSystem
import SwiftUI

struct HomeCardView: View {
    var resources = HomeResourcesUIModel()
    var card: HomeCardModel
    var palateMap: PalateMap
    var cellarWineKeys: Set<String> = []
    /// HOME-R10c: the cards that follow the map are being read again.
    var isRefreshingMatches = false
    /// The whole Home is being read again (after a new note): every card shows its curtain.
    var isReloading = false
    /// The Home is going back to its top after a note from the Hero: the Hero folds once it is there.
    var heroHoldsOpen = false
    var onInvite: () -> Void = {}
    var onOpenFriends: () -> Void = {}
    var onOpenLastTable: () -> Void = {}
    var onOpenMapHistory: () -> Void = {}
    var onOpenLesson: (HomeLessonSuggestion) -> Void = { _ in }
    var onOpenCourse: (String) -> Void = { _ in }
    var onOpenGlossary: (GlossaryTerm) -> Void = { _ in }
    var onOpenLearn: (CourseKind) -> Void = { _ in }
    var onShowLess: (_ then: @escaping () -> Void) -> Void = { $0() }
    var onOpenWine: (WineSheetModel) -> Void = { _ in }
    var onSaveToCellar: (Wine) -> Void = { _ in }

    var body: some View {
        cardView
            .environment(\.cardIsLoading, isReloading)
            // The taps some cards take from outside their glass wait for the new content too.
            .allowsHitTesting(!isReloading)
    }

    /// The cards that follow the map also load when only the matches are read again.
    private var followsMapLoading: Bool { isReloading || isRefreshingMatches }

    @ViewBuilder private var cardView: some View {
        switch card {
        case .header: EmptyView() // drawn by HomeHeader, pinned above the scroll
        case let .topMatch(wine):
            HeroCard(resources: resources, wine: wine, palateMap: palateMap, isInCellar: cellarWineKeys.contains(wine.id), isLoading: followsMapLoading,
                    holdsOpen: heroHoldsOpen,
                    onShowLess: onShowLess, onSaveToCellar: { onSaveToCellar(wine) })
        case let .friends(state):
            // HOME-R11: no friend, the invite; one, the last table (FRI-R17); more, the Friends tab.
            FriendsCard(resources: resources, state: state)
                .contentShape(Rectangle())
                .onTapGesture {
                    switch state {
                    case .noFriends: onInvite()
                    case .hasMatch: onOpenLastTable()
                    case .hasFriends: onOpenFriends()
                    }
                }
        case let .continueLesson(course):
            ContinueLessonCard(resources: resources, course: course)
                .contentShape(Rectangle())
                .onTapGesture { onOpenCourse(course.id) }
        case let .changedMapCard(axis, delta):
            // HOME-R17: You › Map, at "Over time".
            ChangedMapCard(resources: resources, axis: axis, delta: delta, palateMap: palateMap)
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpenMapHistory)
                .accessibilityAddTraits(.isButton)
        case let .learnShortcuts(suggestions): LearnShortcutsCard(resources: resources, suggestions: suggestions, onOpen: onOpenLesson)
        case let .wordOfTheDay(term):
            Button { onOpenGlossary(term) } label: {
                WordOfTheDayCard(resources: resources, term: term)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Open glossary")
        case let .winesForPalate(suggestions):
            WinesForPalateCard(resources: resources, suggestions: suggestions, isLoading: followsMapLoading) { onOpenWine(.palate($0)) }
        case let .chooseYourWine(catalog):
            ChooseYourWineCard(resources: resources, palateMap: palateMap, catalog: catalog) { suggestions, direction in
                onOpenWine(.discovery(suggestions: WineList(suggestions), direction: direction))
            }
        }
    }
}
