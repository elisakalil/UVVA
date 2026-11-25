import Core
import Foundation
import Match
import Testing
@testable import Friends

@MainActor
struct GroupTableTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    let userMap = PalateMap.positions([.acidity: 7, .fruit: 7])

    let sharing = SharingFake()

    func makeList(onAddToCellar: @escaping (Wine) -> Void = { _ in }) -> FriendsViewModel {
        FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository, catalog: CatalogStub(),
                       social: social, contacts: ContactsFake(access: .denied), sharing: sharing, wines: WineLookupStub())
            .makeViewModel(onAddToCellar: onAddToCellar)
    }

    /// The table of the friends named, loaded.
    func loadedTable(_ names: [String],
                     onAddToCellar: @escaping (Wine) -> Void = { _ in }) async throws -> GroupTableViewModel {
        let list = await loadedList(names, onAddToCellar: onAddToCellar)
        list.startSelecting()
        for name in names { list.toggle(name.lowercased()) }
        list.findBottle()
        let table = try #require(list.groupTable)
        await table.load()
        return table
    }

    func befriend(_ names: [String]) {
        for name in names {
            let id = name.lowercased()
            social.profile(id, name, map: userMap)
            social.request("elisa", id)
            social.request(id, "elisa")
        }
    }

    func loadedList(_ names: [String], onAddToCellar: @escaping (Wine) -> Void = { _ in }) async -> FriendsViewModel {
        befriend(names)
        let list = makeList(onAddToCellar: onAddToCellar)
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
        let friends = [7.0, 7, 8].enumerated().map { friend("f\($0.offset)", PalateMap.positions([.acidity: $0.element])) }
        let builder = GroupTablePresentationBuilder(userMap: PalateMap.positions([.acidity: 6]), friends: friends, bottles: nil,
                                                    resources: GroupTableResourcesUIModel())
        let acidity = builder.readings.first { $0.name == "Acidity" }
        #expect(acidity?.rangeText == "6–8")
        #expect(acidity?.low == 6.0 / 9)
        #expect(acidity?.high == 8.0 / 9)
        #expect((acidity?.middle ?? 0) > 6.0 / 9 && (acidity?.middle ?? 1) < 8.0 / 9)
    }

    @Test func FRI_R19_noSharedAxes_tableOfFour() {
        let friends = [friend("a", PalateMap.positions([.tannin: 8])), friend("b", PalateMap.positions([.sweetness: 8])),
                       friend("c", PalateMap.positions([.floral: 8]))]
        let builder = GroupTablePresentationBuilder(userMap: PalateMap.positions([.acidity: 8]), friends: friends, bottles: nil,
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
        #expect(model.memberNames == ["Marina", "Bia", "You"])
        #expect(model.matchValueText == "100%")
        #expect(model.mapsText == "3 maps · one bottle")
        #expect(model.guestsText == "The 3 of you")
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

    // MARK: FRI-R13, R15a · Set a table, as on a friend

    @Test func FRI_R13a_settingTheDinner_buildsTheCoursesChosen_inItsSheet() async throws {
        let table = try await loadedTable(["Marina", "Bia"])
        #expect(table.uiModel.bottles?.map(\.courseText) == ["Starter", "Main", "Dessert"])
        #expect(table.uiModel.togetherWines?.map(\.id) == table.uiModel.bottles?.map(\.id))
        #expect(!table.uiModel.isTableOpen)
        table.toggleCourse(.starter)
        await table.setTable()
        #expect(table.uiModel.isTableOpen)
        #expect(table.uiModel.bottles?.map(\.courseText) == ["Main", "Dessert"])
        #expect(table.uiModel.recipes?.map(\.courseText) == ["Main", "Dessert"])
        table.closeTable()
        #expect(!table.uiModel.isTableOpen)
        #expect(table.uiModel.dinner.buttonTitle == "Set the perfect dinner")
        table.pickFood(.vegetarian)
        #expect(table.uiModel.dinner.buttonTitle == "Set it again")
    }

    // MARK: Friend Wine at a group table

    @Test func aBottleToOpenTogether_readsOnEveryMap_andGoesToTheWholeTable() async throws {
        let table = try await loadedTable(["Marina", "Bia"])
        let bottle = try #require(table.uiModel.togetherWines?.first)
        table.openTableWine(bottle.id)
        let wine = try #require(table.uiModel.friendWine)
        #expect(wine.content.percentageCaption == "match with your 3 maps")
        #expect(wine.people.map(\.name) == ["You", "Marina", "Bia"])
        #expect(wine.footer == .send(title: "Send to the table", isEnabled: true, failed: nil))
        await table.sendWine()
        #expect(Set(sharing.records.map(\.to)) == ["marina", "bia"])
        #expect(table.uiModel.friendWine?.footer == .send(title: "Sent to the table", isEnabled: false, failed: nil))
        await table.sendWine()
        #expect(sharing.records.count == 2)
    }

    @Test func sendingAgain_afterAFailure_onlyGoesToThoseItMissed() async throws {
        let table = try await loadedTable(["Marina", "Bia"])
        sharing.failSending(to: ["bia"])
        let bottle = try #require(table.uiModel.togetherWines?.first)
        table.openTableWine(bottle.id)
        await table.sendWine()
        #expect(sharing.records.map(\.to) == ["marina"])
        #expect(table.uiModel.friendWine?.footer
                == .send(title: "Send to the table", isEnabled: true, failed: "It did not send. Try again."))
        sharing.failSending(to: [])
        await table.sendWine()
        #expect(sharing.records.map(\.to) == ["marina", "bia"])
    }

    @Test func aBottleToOpenTogether_addToCellar_closesIt_thenOpensTheNewNote() async throws {
        var added: [String] = []
        let table = try await loadedTable(["Marina", "Bia"], onAddToCellar: { added.append($0.id) })
        let bottle = try #require(table.uiModel.togetherWines?.first)
        table.openTableWine(bottle.id)
        #expect(table.uiModel.friendWine?.cellar == .add)
        table.addWineToCellar()
        #expect(table.uiModel.friendWine == nil)
        #expect(added.isEmpty)
        table.wineDismissed()
        #expect(added == [bottle.id])
        // Closed any other way, nothing opens.
        table.openTableWine(bottle.id)
        table.closeWine()
        table.wineDismissed()
        #expect(added == [bottle.id])
    }

    @Test func scannedWine_readsTheMatchOnEveryMap_andEachOne() {
        let wine = CatalogStub.wines[1]
        let maps = [PalateMap.positions([.tannin: 8]), PalateMap.positions([.oak: 7])]
        let all = TableMatch.crossed([userMap] + maps)
        let model = FriendWinePresentationBuilder(
            wine: wine, reader: .table(friendNames: ["Marina", "Bia"], userMap: userMap, friendMaps: maps)).build()
        #expect(model.content.palate == all)
        #expect(model.content.percentage == "\(Similarity.percent(wine.profile, all))%")
        #expect(model.strings.comparison == "This wine and the 3 of you")
        #expect(model.people.map(\.percentage) == ["\(Similarity.percent(wine.profile, userMap))%",
                                                    "\(Similarity.percent(wine.profile, maps[0]))%",
                                                    "\(Similarity.percent(wine.profile, maps[1]))%"])
    }

    @Test func withoutAScanner_thereIsNoPlus() async throws {
        let table = try await loadedTable(["Marina", "Bia"])
        #expect(table.uiModel.canScan == false)
        table.scanWine()
        #expect(table.uiModel.scanner == nil)
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
