import Core
import Foundation
import Match
import Testing
@testable import Friends

@MainActor
struct FriendProfileTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    let userMap = PalateMap.positions([.acidity: 7, .fruit: 6])

    func makeList() -> FriendsViewModel {
        FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository, catalog: CatalogStub(),
                       social: social, contacts: ContactsFake(access: .denied))
            .makeViewModel()
    }

    func befriend(_ id: String, _ name: String, map: PalateMap) {
        social.profile(id, name, map: map)
        social.request("elisa", id)
        social.request(id, "elisa")
    }

    func builder(friend: PalateMap) -> FriendProfilePresentationBuilder {
        FriendProfilePresentationBuilder(friend: Friend(id: "m", name: "Marina", map: friend, addedAt: .now),
                                         userMap: userMap, bottles: nil, resources: FriendProfileResourcesUIModel())
    }

    // MARK: FRI-R10 · Três tabs

    @Test func FRI_R10_tappingAFriend_opensTheirPalate() async {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        #expect(list.profile?.uiModel.tab == .map)
        #expect(list.profile?.uiModel.name == "Marina")
        list.profile?.selectTab(.compatibility)
        #expect(list.profile?.uiModel.tab == .compatibility)
        list.profile?.close()
        #expect(list.profile == nil)
    }

    // MARK: FRI-R11 · Palate

    @Test func FRI_R11_readings_everyAxis_leadersStronger() {
        let readings = builder(friend: PalateMap.positions([.acidity: 8, .fruit: 7, .body: 6])).readings
        #expect(readings.count == PalateAxis.allCases.count)
        #expect(readings.filter(\.isStrong).map(\.name).sorted() == ["Acidity", "Body", "Fruit"])
        #expect(readings.first { $0.name == "Acidity" }?.level == 8)
    }

    @Test func FRI_R11_giftWines_leanOnTheirLeadingReadings() async {
        let map = PalateMap.positions([.acidity: 8, .fruit: 7, .body: 6])
        befriend("marina", "Marina", map: map)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        #expect(list.profile?.uiModel.giftWines == nil)
        await list.profile?.load()
        let model = list.profile?.uiModel
        let wines = model?.giftWines ?? []
        #expect(model?.giftTitle == "Picks for Marina")
        #expect(!wines.isEmpty)
        #expect(wines.allSatisfy { ["Acidity", "Fruit", "Body"].contains($0.axisName) })
        // Under the wine, only the reading and how strong, as the Home: "High acidity", "Full body".
        #expect(wines.allSatisfy { row in
            row.axisName == "Body" ? row.axisText.hasSuffix("body") : row.axisText.hasSuffix(row.axisName.lowercased())
        })
    }

    @Test func FRI_R11_cardTitles_useTheFirstName() {
        var model = FriendProfileUIModel()
        FriendProfilePresentationBuilder(friend: Friend(id: "b", name: "Beatriz Damas", map: userMap, addedAt: .now),
                                         userMap: userMap, resources: FriendProfileResourcesUIModel())
            .build(into: &model)
        #expect(model.mapTitle == "Beatriz Map")
        #expect(model.giftTitle == "Picks for Beatriz")
    }

    @Test func FRI_R11_friendWine_readsTheMatchOnTheFriendsMap() {
        let wine = CatalogStub.wines[0]
        let friendMap = PalateMap.positions([.acidity: 8, .fruit: 6])
        let model = FriendWinePresentationBuilder(wine: wine, reader: .friend(name: "Marina", map: friendMap),
                                                  sending: .sent).build()
        #expect(model.content.percentage == "\(Similarity.percent(wine.profile, friendMap))%")
        #expect(model.content.palate == friendMap)
        #expect(model.content.percentageCaption == "match with Marina's map")
        #expect(model.content.sharedLine?.hasSuffix("Marina's map.") == true)
        #expect(model.strings.comparison == "This wine and Marina")
        #expect(model.strings.palateLegend == "Marina's map")
        #expect(model.footer == .send(title: "Sent to Marina", isEnabled: false, failed: nil))
        #expect(model.content.findURL != nil)
    }

    @Test func FRI_R12a_scannedWine_readsTheMatchOnBothMaps_andEachOne() {
        let wine = CatalogStub.wines[1]
        let friendMap = PalateMap.positions([.tannin: 8, .oak: 7])
        let both = TableMatch.crossed([userMap, friendMap])
        let model = FriendWinePresentationBuilder(
            wine: wine, reader: .both(friendName: "Marina", userMap: userMap, friendMap: friendMap)).build()
        #expect(model.content.percentage == "\(Similarity.percent(wine.profile, both))%")
        #expect(model.content.palate == both)
        #expect(model.content.percentageCaption == "match with your two maps")
        #expect(model.strings.comparison == "This wine and you two")
        #expect(model.people.map(\.name) == ["You", "Marina"])
        #expect(model.people.map(\.percentage) == ["\(Similarity.percent(wine.profile, userMap))%",
                                                    "\(Similarity.percent(wine.profile, friendMap))%"])
    }

    @Test func aWineForTheTwo_canGoToTheCellar_besideTheMagnifyingGlass() {
        let wine = CatalogStub.wines[1]
        let friendMap = PalateMap.positions([.tannin: 8, .oak: 7])
        let both = FriendWinePresentationBuilder.Reader.both(friendName: "Marina", userMap: userMap, friendMap: friendMap)
        #expect(FriendWinePresentationBuilder(wine: wine, reader: both).build().cellar == .add)
        #expect(FriendWinePresentationBuilder(wine: wine, reader: both, isInCellar: true).build().cellar == .inCellar)
        // A wine of the friend's Map keeps "Find the wine" alone; a wine received is kept from its footer.
        #expect(FriendWinePresentationBuilder(wine: wine, reader: .friend(name: "Marina", map: friendMap)).build().cellar == nil)
        #expect(FriendWinePresentationBuilder(wine: wine, reader: .you(senderName: "Marina", map: userMap)).build().cellar == nil)
    }

    @Test func FRI_R12a_withoutAScanner_thereIsNoScan() async throws {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        let profile = try #require(list.profile)
        #expect(profile.uiModel.canScan == false)
        profile.scanWine()
        #expect(profile.uiModel.scanner == nil)
    }

    // MARK: FRI-R12 · Compatibility

    @Test func FRI_R12_title_withTheCompatibility() {
        var model = FriendProfileUIModel()
        builder(friend: userMap).build(into: &model)
        #expect(model.matchTitle == "100% of your palate map matches Marina")
    }

    @Test func FRI_R12_readingByReading_bothReadings_andHowFarApart() {
        var model = FriendProfileUIModel()
        builder(friend: userMap).build(into: &model)
        #expect(model.compareRows.count == PalateAxis.allCases.count)
        #expect(model.compareRows.allSatisfy { $0.verdict == "Same" && $0.isSame && $0.mineLevel == $0.theirsLevel })
        #expect(model.compatibilityText == "100%")
        #expect(model.matchCaption == "of your palate map matches Marina")
        #expect(model.guestsText == "You & Marina")
    }

    @Test func FRI_R12_readingByReading_farApart_isOpposed() {
        let row = builder(friend: PalateMap.positions([.tannin: 9])).compareRows.first { $0.name == "Tannin" }
        #expect(row?.verdict == "Opposed")
        #expect(row?.isSame == false)
    }

    @Test func FRI_R12_twoSharedAxes() {
        #expect(builder(friend: PalateMap.positions([.acidity: 7.5, .fruit: 6.5])).overlapPhrase
                == "You both want acidity and fruit in a glass.")
    }

    @Test func FRI_R12_threeSharedAxes() {
        let both = PalateMap.positions([.acidity: 8, .fruit: 7, .spice: 6])
        let builder = FriendProfilePresentationBuilder(friend: Friend(id: "m", name: "M", map: both, addedAt: .now),
                                                       userMap: both, bottles: nil, resources: FriendProfileResourcesUIModel())
        #expect(builder.overlapPhrase == "You both want acidity, fruit and spice in a glass.")
    }

    @Test func FRI_R12_noSharedAxes() {
        #expect(builder(friend: PalateMap.positions([.tannin: 8, .oak: 8])).overlapPhrase
                == "You barely overlap — you like different things.")
    }

    @Test func FRI_R12_openThisTogether_threeBottles_withAxisAndWhy() async {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        await list.profile?.load()
        let bottles = list.profile?.uiModel.bottles ?? []
        #expect(bottles.count == 3)
        #expect(bottles.allSatisfy { !$0.why.isEmpty && !$0.axisText.isEmpty })
    }

    // MARK: FRI-R15 · Menu

    @Test func FRI_R15_menu_starterMainDessert_eachWithItsDish() async {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        await list.profile?.load()
        let model = list.profile?.uiModel
        #expect(model?.dinnerTitle == "The perfect dinner for You & Marina")
        #expect(model?.bottles?.map(\.courseText) == ["Starter", "Main", "Dessert"])
        #expect(model?.bottles?.map(\.dishTitle) == ["Grilled sardines", "Mushroom risotto", "Pastel de nata"])
    }

    // MARK: FRI-R17 · Última mesa

    @Test func FRI_R17_settingTheTable_keepsItAsTheLast() async throws {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        #expect(try await repository.lastTable() == nil)
        await list.profile?.setTable()
        #expect(list.profile?.uiModel.isTableOpen == true)
        #expect(try await repository.lastTable() == ["marina"])
    }

    @Test func HOME_R11_matchCard_opensTheLastTable() async throws {
        befriend("marina", "Marina", map: userMap)
        befriend("rui", "Rui", map: PalateMap.positions([.spice: 8]))
        try await repository.saveLastTable(["rui"])
        let list = makeList()
        await list.openLastTable()
        #expect(list.profile?.id == "rui")
        #expect(list.profile?.uiModel.tab == .compatibility)
        #expect(list.profile?.uiModel.isTableOpen == true)
    }

    @Test func HOME_R11_noLastTable_opensTheOnlyFriend() async {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.openLastTable()
        #expect(list.profile?.id == "marina")
        #expect(list.profile?.uiModel.tab == .compatibility)
        #expect(list.profile?.uiModel.isTableOpen == true)
    }

    @Test func HOME_R04b_newFriendNotification_opensOnlyTheProfile_withoutATable() async throws {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.openFriendProfile("marina")
        #expect(list.profile?.id == "marina")
        #expect(list.profile?.uiModel.tab == .map)
        #expect(list.profile?.uiModel.isTableOpen == false)
        await list.profile?.load()
        #expect(list.profile?.uiModel.isTableOpen == false)
        #expect(try await repository.lastTable() == nil)
        #expect(list.groupTable == nil)
    }

    // MARK: D4 · Remover

    @Test func D4_remove_takesTheRequestBack_withoutTellingThem() async throws {
        befriend("marina", "Marina", map: userMap)
        var changes = 0
        let list = FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository,
                                  catalog: CatalogStub(), social: social, contacts: ContactsFake(access: .denied))
            .makeViewModel(onFriendsChange: { changes += 1 })
        await list.load()
        changes = 0
        list.openFriend("marina")
        list.profile?.askToRemove()
        #expect(list.profile?.uiModel.isConfirmingRemoval == true)
        await list.profile?.confirmRemoval()
        #expect(list.profile == nil)
        #expect(list.uiModel.friends.isEmpty)
        #expect(changes == 1)
        #expect(social.requests.map { "\($0.from)-\($0.to)" } == ["marina-elisa"])
        // Her request is still there until her next refresh, but it never shows as a request.
        await list.reload()
        #expect(list.uiModel.requests.isEmpty)
        #expect(list.uiModel.friends.isEmpty)
    }

    @Test func D4_cancelRemoval_keepsTheFriend() async {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        list.profile?.askToRemove()
        list.profile?.cancelRemoval()
        #expect(list.profile?.uiModel.isConfirmingRemoval == false)
        #expect(social.requests.count == 2)
    }
}
