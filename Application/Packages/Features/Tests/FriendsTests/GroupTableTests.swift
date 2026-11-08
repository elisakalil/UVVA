import Core
import Foundation
import Testing
@testable import Friends

@MainActor
struct GroupTableTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    let userMap = PalateMap([.acidity: 7, .fruit: 7])

    func makeList() -> FriendsViewModel {
        FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository, catalog: CatalogStub(),
                       social: social, contacts: ContactsFake(access: .denied))
            .makeViewModel()
    }

    func befriend(_ names: [String]) {
        for name in names {
            let id = name.lowercased()
            social.profile(id, name, map: userMap)
            social.request("elisa", id)
            social.request(id, "elisa")
        }
    }

    func loadedList(_ names: [String]) async -> FriendsViewModel {
        befriend(names)
        let list = makeList()
        await list.load()
        return list
    }

    func friend(_ id: String, _ map: PalateMap) -> Friend { Friend(id: id, name: id.capitalized, map: map, addedAt: .now) }

    // MARK: FRI-R18 · Escolher quem vem

    @Test func FRI_R18_selectShows_withTwoFriendsOrMore() async {
        #expect(await loadedList(["Marina"]).uiModel.canSelect == false)
        #expect(await loadedList(["Bia", "Rui"]).uiModel.canSelect == true)
    }

    @Test func FRI_R18_oneChosen_buttonAsksForTwo_andIsInactive() async {
        let list = await loadedList(["Marina", "Bia", "Rui"])
        list.startSelecting()
        list.toggle("marina")
        #expect(list.uiModel.selectButtonText == "Pick at least two friends")
        #expect(list.uiModel.canFindBottle == false)
        list.findBottle()
        #expect(list.groupTable == nil)
    }

    @Test func FRI_R18_threeChosen_findABottleForThese3() async {
        let list = await loadedList(["Marina", "Bia", "Rui"])
        list.startSelecting()
        for id in ["marina", "bia", "rui"] { list.toggle(id) }
        #expect(list.uiModel.selectButtonText == "Find a bottle for these 3")
        #expect(list.uiModel.canFindBottle)
    }

    @Test func FRI_R18_tappingAgain_unchooses() async {
        let list = await loadedList(["Marina", "Bia"])
        list.startSelecting()
        list.toggle("marina")
        list.toggle("marina")
        #expect(list.uiModel.selectedIDs.isEmpty)
    }

    @Test func D6_atMostFiveFriends_andItSaysSo() async {
        let list = await loadedList(["A", "B", "C", "D", "E", "F"])
        list.startSelecting()
        for id in ["a", "b", "c", "d", "e", "f"] { list.toggle(id) }
        #expect(list.uiModel.selectedIDs == ["a", "b", "c", "d", "e"])
        #expect(list.uiModel.tableFullText == "A table seats you and 5 friends")
    }

    @Test func FRI_R18_cancel_leavesTheChoice() async {
        let list = await loadedList(["Marina", "Bia"])
        list.startSelecting()
        list.toggle("marina")
        list.cancelSelecting()
        #expect(list.uiModel.isSelecting == false)
        #expect(list.uiModel.selectedIDs.isEmpty)
    }

    @Test func FRI_R18_findABottle_opensTheTable_andEndsTheChoice() async throws {
        let list = await loadedList(["Marina", "Bia"])
        list.startSelecting()
        list.toggle("marina")
        list.toggle("bia")
        list.findBottle()
        #expect(list.groupTable?.id == "marina+bia")
        #expect(list.uiModel.isSelecting == false)
        await list.groupTable?.load()
        #expect(list.groupTable?.uiModel.bottles?.count == 3)
        #expect(try await repository.lastTable() == ["marina", "bia"])
    }

    // MARK: FRI-R19 · Resultado

    @Test func FRI_R19_rangeFromLowestToHighest() {
        let friends = [7.0, 7, 8].enumerated().map { friend("f\($0.offset)", PalateMap([.acidity: $0.element])) }
        let builder = GroupTablePresentationBuilder(userMap: PalateMap([.acidity: 6]), friends: friends, bottles: nil,
                                                    resources: GroupTableResourcesUIModel())
        #expect(builder.readings.first { $0.name == "Acidity" }?.rangeText == "6–8")
    }

    @Test func FRI_R19_noSharedAxes_tableOfFour() {
        let friends = [friend("a", PalateMap([.tannin: 8])), friend("b", PalateMap([.sweetness: 8])),
                       friend("c", PalateMap([.floral: 8]))]
        let builder = GroupTablePresentationBuilder(userMap: PalateMap([.acidity: 8]), friends: friends, bottles: nil,
                                                    resources: GroupTableResourcesUIModel())
        #expect(builder.phrase == "Nothing lines up across all 4 — the menu is built on compromise.")
    }

    @Test func FRI_R19_titlesCountEveryMapAtTheTable() {
        let friends = [friend("marina", userMap), friend("bia", userMap)]
        var model = GroupTableUIModel()
        GroupTablePresentationBuilder(userMap: userMap, friends: friends, bottles: nil, resources: GroupTableResourcesUIModel())
            .build(into: &model)
        #expect(model.matchTitle == "100% match across all 3 palate maps at the table")
        #expect(model.phrase == "You all want acidity and fruit in a glass.")
        #expect(model.dinnerTitle == "The perfect dinner for The 3 of you")
        #expect(model.membersText == "You, Marina and Bia")
    }

    @Test func FRI_R19_readings_startCollapsed() async {
        let list = await loadedList(["Marina", "Bia"])
        list.startSelecting()
        list.toggle("marina")
        list.toggle("bia")
        list.findBottle()
        #expect(list.groupTable?.uiModel.isReadingsExpanded == false)
        list.groupTable?.toggleReadings()
        #expect(list.groupTable?.uiModel.isReadingsExpanded == true)
    }

    // MARK: FRI-R17 · Última mesa de grupo

    @Test func FRI_R17_lastGroupTable_opensAgain() async throws {
        befriend(["Marina", "Bia", "Rui"])
        try await repository.saveLastTable(["bia", "rui"])
        let list = makeList()
        await list.openLastTable()
        #expect(list.groupTable?.id == "bia+rui")
        #expect(list.profile == nil)
    }
}
