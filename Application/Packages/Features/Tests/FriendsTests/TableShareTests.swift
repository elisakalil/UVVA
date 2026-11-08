import Core
import Foundation
import Testing
@testable import Friends

@MainActor
struct TableShareTests {
    let social = SocialFake()
    let repository = FriendsRepositoryFake()
    let userMap = PalateMap([.acidity: 7, .fruit: 7])

    var bottles: [TableBottle] {
        zip(TableCourse.allCases, zip(CatalogStub.wines, CatalogStub.recipes)).map { course, pair in
            TableBottle(course: course, wine: pair.0, recipe: pair.1, axis: .acidity)
        }
    }

    func builder(_ friends: [String]) -> TableShareBuilder {
        TableShareBuilder(friendNames: friends, userName: "Elisa", bottles: bottles, resources: TableResourcesUIModel())
    }

    // MARK: FRI-R21 · Três formatos

    @Test func FRI_R21_tableForTwo_invite_namesAndLink() {
        let share = builder(["Marina"]).build()
        #expect(share.namesText == "Marina & Elisa")
        #expect(share.link.absoluteString == "https://uvva.app/t/marina-elisa")
        #expect(share.message.contains("Marina & Elisa"))
        #expect(share.message.contains("uvva.app/t/marina-elisa"))
        #expect(share.message.hasPrefix("You're invited to dinner"))
        #expect(share.message.contains("Dinner at mine? I built the menu from both our palate maps. Three courses, three bottles."))
    }

    @Test func FRI_R21_message_carriesTheMenu() {
        let share = builder(["Marina"]).build()
        #expect(share.message.contains("Starter · Alvarinho, Soalheiro — Grilled sardines"))
        #expect(share.message.contains("Dessert · Tawny, Graham's — Pastel de nata"))
    }

    @Test func FRI_R21_shoppingGuide_courseAskForAndDish() {
        let share = builder(["Marina"]).build()
        #expect(share.courses.map(\.courseText) == ["Starter", "Main", "Dessert"])
        #expect(share.courses.first?.askForText == "Ask for: Soalheiro Alvarinho")
        #expect(share.courses.first?.dishText == "Grilled sardines")
    }

    @Test func FRI_R21_link_withoutAccentsOrSpaces() {
        #expect(TableShareBuilder.slug(["João Lima", "Élisa"]) == "joao-lima-elisa")
    }

    // MARK: FRI-R22 · Texto do grupo

    @Test func FRI_R22_groupTable_everyName_andAllOurMaps() {
        let share = builder(["Marina", "Bia"]).build()
        #expect(share.namesText == "Marina, Bia & Elisa")
        #expect(share.link.absoluteString == "https://uvva.app/t/marina-bia-elisa")
        #expect(share.message.contains("all our palate maps"))
        #expect(!share.message.contains("both our"))
    }

    // MARK: Share nas mesas

    @Test func share_waitsForTheBottles_thenOpensAndCloses() async {
        social.profile("marina", "Marina", map: userMap)
        social.request("elisa", "marina")
        social.request("marina", "elisa")
        let list = FriendsFactory(profiles: ProfilesStub(), maps: MapStub(map: userMap), friends: repository,
                                  catalog: CatalogStub(), social: social, contacts: ContactsFake(access: .denied))
            .makeViewModel()
        await list.load()
        list.openFriend("marina")
        let profile = list.profile
        #expect(profile?.uiModel.share == nil)
        profile?.openShare()
        #expect(profile?.uiModel.isSharing == false)
        await profile?.load()
        #expect(profile?.uiModel.share?.namesText == "Marina & Elisa")
        profile?.openShare()
        #expect(profile?.uiModel.isSharing == true)
        profile?.closeShare()
        #expect(profile?.uiModel.isSharing == false)
    }
}
