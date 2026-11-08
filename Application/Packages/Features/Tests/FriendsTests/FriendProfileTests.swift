import Core
import Foundation
import Testing
@testable import Friends

@MainActor
struct FriendProfileTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    let userMap = PalateMap([.acidity: 7, .fruit: 6])

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
        #expect(list.profile?.uiModel.tab == .palate)
        #expect(list.profile?.uiModel.name == "Marina")
        list.profile?.selectTab(.compatibility)
        #expect(list.profile?.uiModel.tab == .compatibility)
        list.profile?.close()
        #expect(list.profile == nil)
    }

    // MARK: FRI-R11 · Palate

    @Test func FRI_R11_readings_everyAxis_leadersStronger() {
        let readings = builder(friend: PalateMap([.acidity: 8, .fruit: 7, .body: 6])).readings
        #expect(readings.count == PalateAxis.allCases.count)
        #expect(readings.filter(\.isStrong).map(\.name).sorted() == ["Acidity", "Body", "Fruit"])
        #expect(readings.first { $0.name == "Acidity" }?.level == 8)
    }

    // MARK: FRI-R12 · Compatibility

    @Test func FRI_R12_title_withTheCompatibility() {
        var model = FriendProfileUIModel()
        builder(friend: userMap).build(into: &model)
        #expect(model.matchTitle == "100% of your palate map matches Marina")
    }

    @Test func FRI_R12_twoSharedAxes() {
        #expect(builder(friend: PalateMap([.acidity: 7.5, .fruit: 6.5])).overlapPhrase
                == "You both want acidity and fruit in a glass.")
    }

    @Test func FRI_R12_threeSharedAxes() {
        let both = PalateMap([.acidity: 8, .fruit: 7, .spice: 6])
        let builder = FriendProfilePresentationBuilder(friend: Friend(id: "m", name: "M", map: both, addedAt: .now),
                                                       userMap: both, bottles: nil, resources: FriendProfileResourcesUIModel())
        #expect(builder.overlapPhrase == "You both want acidity, fruit and spice in a glass.")
    }

    @Test func FRI_R12_noSharedAxes() {
        #expect(builder(friend: PalateMap([.tannin: 8, .oak: 8])).overlapPhrase
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

    @Test func FRI_R17_openingTheTable_keepsItAsTheLast() async throws {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        #expect(try await repository.lastTable() == nil)
        list.profile?.selectTab(.table)
        await list.profile?.load()
        #expect(try await repository.lastTable() == ["marina"])
    }

    @Test func HOME_R11_matchCard_opensTheLastTable() async throws {
        befriend("marina", "Marina", map: userMap)
        befriend("rui", "Rui", map: PalateMap([.spice: 8]))
        try await repository.saveLastTable(["rui"])
        let list = makeList()
        await list.openLastTable()
        #expect(list.profile?.id == "rui")
        #expect(list.profile?.uiModel.tab == .table)
    }

    @Test func HOME_R11_noLastTable_opensTheOnlyFriend() async {
        befriend("marina", "Marina", map: userMap)
        let list = makeList()
        await list.openLastTable()
        #expect(list.profile?.id == "marina")
        #expect(list.profile?.uiModel.tab == .table)
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
