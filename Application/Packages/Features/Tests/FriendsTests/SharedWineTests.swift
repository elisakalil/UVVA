import Core
import Foundation
import Testing
@testable import Friends

/// FRI-R11b, R11c: sending a wine to a friend, and the wines friends sent.
@MainActor
struct SharedWineTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    let sharing = SharingFake()
    let userMap = PalateMap.positions([.acidity: 7, .fruit: 6])

    func makeList(wines: (any WineLookup)? = WineLookupStub(), onAddToCellar: @escaping (Wine) -> Void = { _ in },
                  onHasFriends: @escaping () -> Void = {}) -> FriendsViewModel {
        FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository, catalog: CatalogStub(),
                       social: social, contacts: ContactsFake(access: .denied), sharing: sharing, wines: wines)
            .makeViewModel(onAddToCellar: onAddToCellar, onHasFriends: onHasFriends)
    }

    func befriend(_ id: String, _ name: String) {
        social.profile(id, name, map: userMap)
        social.request("elisa", id)
        social.request(id, "elisa")
    }

    // MARK: FRI-R11b · Send to [name]

    @Test func FRI_R11b_sendToFriend_sendsTheOpenWine_andSaysItWent() async throws {
        befriend("marina", "Marina")
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        let profile = try #require(list.profile)
        await profile.load()
        let wine = try #require(profile.uiModel.giftWines?.first)
        profile.openWine(wine.id)
        #expect(profile.uiModel.friendWine?.footer == .send(title: "Send to Marina", isEnabled: true, failed: nil))
        await profile.sendWine()
        #expect(sharing.records.map(\.id) == ["elisa-marina-\(wine.id)"])
        #expect(sharing.records.first?.to == "marina")
        #expect(profile.uiModel.friendWine?.footer == .send(title: "Sent to Marina", isEnabled: false, failed: nil))
        await profile.sendWine()
        #expect(sharing.records.count == 1)
    }

    @Test func FRI_R11b_sendFailing_saysSo_andCanBeSentAgain() async throws {
        befriend("marina", "Marina")
        sharing.failSending()
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        let profile = try #require(list.profile)
        await profile.load()
        let wine = try #require(profile.uiModel.giftWines?.first)
        profile.openWine(wine.id)
        await profile.sendWine()
        #expect(sharing.records.isEmpty)
        #expect(profile.uiModel.friendWine?.footer
                == .send(title: "Send to Marina", isEnabled: true, failed: "It did not send. Try again."))
    }

    @Test func FRI_R11a_aBottleToOpenTogether_opensOnBothMaps_toSend() async throws {
        befriend("marina", "Marina")
        let list = makeList()
        await list.load()
        list.openFriend("marina")
        let profile = try #require(list.profile)
        await profile.load()
        let bottle = try #require(profile.uiModel.bottles?.first)
        profile.openTableWine(bottle.id)
        let wine = try #require(profile.uiModel.friendWine)
        #expect(wine.id == bottle.id)
        #expect(wine.content.percentageCaption == "match with your two maps")
        #expect(wine.footer == .send(title: "Send to Marina", isEnabled: true, failed: nil))
    }

    // MARK: FRI-R11c · Sent to you

    @Test func FRI_R11c_winesSent_showInSentToYou_newestFirst() async {
        befriend("marina", "Marina")
        sharing.sent(CatalogStub.wines[0], from: "marina", fromName: "Marina", to: "elisa", at: Date(timeIntervalSince1970: 1))
        sharing.sent(CatalogStub.wines[1], from: "marina", fromName: "Marina", to: "elisa", at: Date(timeIntervalSince1970: 2))
        sharing.sent(CatalogStub.wines[2], from: "marina", fromName: "Marina", to: "rui")
        let list = makeList()
        await list.load()
        #expect(list.uiModel.received.map(\.wineName) == ["Chianti", "Alvarinho"])
        #expect(list.uiModel.received.first?.title == "Marina sent you a wine")
    }

    @Test func FRI_R11c_aWineTheCatalogDoesNotHave_showsAsTheSenderSawIt() async {
        befriend("marina", "Marina")
        let scanned = Wine(id: "scanned", name: "Quinta da Pellada", producer: "Álvaro Castro", type: "Red", origin: "Dão",
                           profile: PalateMap([.tannin: 7]))
        sharing.sent(scanned, from: "marina", fromName: "Marina", to: "elisa")
        let list = makeList()
        await list.load()
        #expect(list.uiModel.received.map(\.wineName) == ["Quinta da Pellada"])
    }

    @Test func FRI_R11c_openingAWine_readsItOnTheUsersMap_andAddToCellar_opensTheNewNote() async throws {
        befriend("marina", "Marina")
        sharing.sent(CatalogStub.wines[0], from: "marina", fromName: "Marina", to: "elisa")
        var added: [String] = []
        let list = makeList(onAddToCellar: { added.append($0.id) })
        await list.load()
        let id = try #require(list.uiModel.received.first?.id)
        await list.openReceived(id)
        let wine = try #require(list.uiModel.receivedWine)
        #expect(wine.note == "Marina sent you this wine")
        #expect(wine.content.palate == userMap)
        #expect(wine.content.percentageCaption == "match with your map")
        #expect(wine.footer == .addToCellar(isInCellar: false))
        list.addReceivedToCellar()
        #expect(list.uiModel.receivedWine == nil)
        #expect(added.isEmpty)
        list.receivedDismissed()
        #expect(added == ["white"])
    }

    @Test func FRI_R11c_aPush_opensAWineTheTabHadNotRead() async {
        befriend("marina", "Marina")
        let list = makeList()
        await list.load()
        sharing.sent(CatalogStub.wines[1], from: "marina", fromName: "Marina", to: "elisa")
        await list.openReceived("marina-elisa-red")
        #expect(list.uiModel.receivedWine?.id == "red")
        #expect(list.uiModel.received.map(\.id) == ["marina-elisa-red"])
    }

    @Test func FRI_R11c_withAFriend_theAppIsToldOnce() async {
        befriend("marina", "Marina")
        var told = 0
        let list = makeList(onHasFriends: { told += 1 })
        await list.load()
        await list.reload()
        #expect(told == 1)
    }
}

/// FRI-R13a: the perfect dinner as the user chose it.
@MainActor
struct DinnerPreferencesTests {
    let autumn = Date(timeIntervalSince1970: 1_760_000_000) // October 2025

    let recipes = [
        Recipe(id: "soup", title: "Pumpkin soup", why: "", course: "starter", wineTypes: ["White"], profile: PalateMap([:]),
               minutes: 30, mainIngredient: "vegetable", diet: ["vegetarian"], season: ["autumn", "winter"]),
        Recipe(id: "salad", title: "Summer salad", why: "", course: "starter", wineTypes: ["White"], profile: PalateMap([:]),
               minutes: 15, mainIngredient: "vegetable", diet: ["vegetarian"], season: ["summer"]),
        Recipe(id: "bass", title: "Sea bass", why: "", course: "main", wineTypes: ["White"], profile: PalateMap([:]),
               minutes: 40, mainIngredient: "fish", season: ["spring", "summer", "autumn", "winter"]),
        Recipe(id: "lamb", title: "Slow lamb", why: "", course: "main", wineTypes: ["Red"], profile: PalateMap([:]),
               minutes: 240, mainIngredient: "red meat", season: ["autumn", "winter"]),
        Recipe(id: "brie", title: "Baked brie", why: "", course: "cheese", wineTypes: ["White"], profile: PalateMap([:]),
               minutes: 20, mainIngredient: "cheese", diet: ["vegetarian"]),
        Recipe(id: "tart", title: "Lemon tart", why: "", course: "dessert", wineTypes: ["Sparkling"], profile: PalateMap([:]),
               minutes: 60, mainIngredient: "fruit", diet: ["vegetarian"])
    ]

    @Test func FRI_R13a_byDefault_starterMainAndDessert() {
        let ids = DinnerPreferences().recipes(from: recipes, on: autumn).map(\.id)
        #expect(Set(ids) == ["soup", "salad", "bass", "lamb", "tart"])
    }

    @Test func FRI_R13a_courses_keepAtLeastOne_inServingOrder() {
        var preferences = DinnerPreferences()
        preferences.toggle(.cheese)
        #expect(preferences.courses == [.starter, .main, .cheese, .dessert])
        preferences.toggle(.starter)
        preferences.toggle(.main)
        preferences.toggle(.dessert)
        preferences.toggle(.cheese)
        #expect(preferences.courses == [.cheese])
    }

    @Test func FRI_R13a_fish_keepsFishMains_andTheDessert() {
        var preferences = DinnerPreferences()
        preferences.food = .fish
        let ids = Set(preferences.recipes(from: recipes, on: autumn).map(\.id))
        #expect(ids.contains("bass"))
        #expect(!ids.contains("lamb"))
        #expect(ids.contains("tart"))
    }

    @Test func FRI_R13a_pasta_leadsTheMain_andLeavesTheStarter() {
        let pasta = Recipe(id: "pappardelle", title: "Wild boar pappardelle", why: "", course: "main", wineTypes: ["Red"],
                           profile: PalateMap([:]), ingredients: [Self.base("pappardelle")], mainIngredient: "game")
        let risotto = Recipe(id: "risotto", title: "Mushroom risotto", why: "", course: "main", wineTypes: ["White"],
                             profile: PalateMap([:]), ingredients: [Self.base("arborio rice")], mainIngredient: "vegetable",
                             diet: ["vegetarian"])
        var preferences = DinnerPreferences()
        preferences.food = .pasta
        let ids = Set(preferences.recipes(from: recipes + [pasta, risotto], on: autumn).map(\.id))
        #expect(ids.contains("pappardelle"))
        #expect(!ids.contains("risotto") && !ids.contains("bass"))
        #expect(ids.contains("soup") && ids.contains("tart"))
        preferences.food = .risotto
        #expect(preferences.recipes(from: recipes + [pasta, risotto], on: autumn).filter { $0.course == "main" }.map(\.id)
            == ["risotto"])
    }

    @Test func FRI_R13a_noMain_theStarterTakesTheChoice() {
        var preferences = DinnerPreferences()
        preferences.courses = [.starter, .dessert]
        preferences.food = .seafood
        let prawns = Recipe(id: "prawns", title: "Garlic prawns", why: "", course: "starter", wineTypes: ["White"],
                            profile: PalateMap([:]), mainIngredient: "shellfish")
        #expect(preferences.recipes(from: recipes + [prawns], on: autumn).map(\.id) == ["prawns", "tart"])
        // Nothing built on it: the course keeps its other dishes.
        #expect(Set(preferences.recipes(from: recipes, on: autumn).map(\.id)) == ["soup", "salad", "tart"])
    }

    @Test func FRI_R13a_vegan_holdsForEveryDish() {
        let vegan = Recipe(id: "sorbet", title: "Lemon sorbet", why: "", course: "dessert", wineTypes: ["Sparkling"],
                           profile: PalateMap([:]), diet: ["vegetarian", "vegan"])
        var preferences = DinnerPreferences()
        preferences.food = .vegan
        #expect(preferences.recipes(from: recipes + [vegan], on: autumn).map(\.id) == ["sorbet"])
    }

    private static func base(_ name: String) -> RecipeIngredient {
        RecipeIngredient(name: name, quantity: 300, unit: "g", note: nil, role: "base")
    }

    @Test func FRI_R13a_inSeason_andQuick() {
        var preferences = DinnerPreferences()
        preferences.inSeason = true
        preferences.time = .quick
        let ids = Set(preferences.recipes(from: recipes, on: autumn).map(\.id))
        #expect(ids.contains("soup"))
        #expect(!ids.contains("salad"))
        #expect(ids.contains("bass"))
        #expect(!ids.contains("lamb"))
    }

    @Test func FRI_R13a_aCourseLeftEmpty_letsTheSeasonAndTimeGo() {
        var preferences = DinnerPreferences()
        preferences.courses = [.dessert]
        preferences.time = .quick
        #expect(preferences.recipes(from: recipes, on: autumn).map(\.id) == ["tart"])
    }

    @Test func FRI_R13a_settingTheDinner_buildsTheCoursesChosen() async throws {
        let social = SocialFake()
        let repository = FriendsRepositoryFake()
        let userMap = PalateMap.positions([.acidity: 7, .fruit: 6])
        social.profile("marina", "Marina", map: userMap)
        social.request("elisa", "marina")
        social.request("marina", "elisa")
        let list = FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository,
                                  catalog: CatalogStub(), social: social, contacts: ContactsFake(access: .denied))
            .makeViewModel()
        await list.load()
        list.openFriend("marina")
        let profile = try #require(list.profile)
        await profile.load()
        #expect(profile.uiModel.bottles?.map(\.courseText) == ["Starter", "Main", "Dessert"])
        profile.toggleCourse(.starter)
        #expect(profile.uiModel.dinner.courses.first?.isOn == false)
        await profile.setTable()
        #expect(profile.uiModel.isTableOpen)
        #expect(profile.uiModel.bottles?.map(\.courseText) == ["Main", "Dessert"])
        // FRI-R15a: each course with its dish and how to make it, in the sheet.
        #expect(profile.uiModel.recipes?.map(\.courseText) == ["Main", "Dessert"])
        #expect(profile.uiModel.recipes?.map(\.title) == profile.uiModel.bottles?.map(\.dishTitle))
        profile.closeTable()
        #expect(!profile.uiModel.isTableOpen)
        #expect(profile.uiModel.dinner.buttonTitle == "Set the perfect dinner")
        profile.pickFood(.vegetarian)
        #expect(profile.uiModel.dinner.buttonTitle == "Set it again")
    }
}
