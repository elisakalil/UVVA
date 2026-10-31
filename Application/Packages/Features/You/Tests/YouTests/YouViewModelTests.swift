import Core
import Foundation
import Testing
@testable import You

@MainActor
struct YouViewModelTests {
    let elisa = Profile(id: "u1", authProvider: .apple, authUserID: "a1", firstName: "Elisa", phone: "+351912345678")
    let quiz = MapChange(date: Date(timeIntervalSince1970: 1_790_000_000), cause: .quiz,
                         values: [.acidity: 7, .fruit: 6, .body: 5, .sweetness: 1])

    final class Actions {
        var log: [String] = []
    }

    private func make(profiles: ProfilesSpy? = nil, social: SocialSpy = SocialSpy(), reminders: RemindersSpy = RemindersSpy(),
                      history: [MapChange]? = nil, actions: Actions = Actions()) async -> YouViewModel {
        let viewModel = YouViewModel(profiles: profiles ?? ProfilesSpy(elisa), maps: MapsStub(history: history ?? [quiz]),
                                     catalog: CatalogStub(), social: social, reminders: reminders, scheduler: reminders,
                                     onRedoMap: { actions.log.append("redo") }, onOpenLearn: { actions.log.append("learn") },
                                     onSignOut: { actions.log.append("signOut") },
                                     onAccountDeleted: { actions.log.append("deleted") })
        await viewModel.load()
        return viewModel
    }

    // MARK: YOU-R01 · Header

    @Test func YOU_R01_header_showsNameAndSignature_withoutHandle() async {
        let header = await make().header
        #expect(header.name == "Elisa")
        #expect(header.signature == "ACIDITY · FRUIT · BODY")
        #expect(!header.name.contains("@") && !header.signature.contains("@"))
    }

    // MARK: YOU-R02, R04, R07 · Progress

    @Test func YOU_R02_opensOnProgress() async {
        #expect(await make().tab == .progress)
    }

    @Test func YOU_R04_R07_newUser_zeros_andThePathsFirstModule() async {
        let progress = await make().progress
        #expect(progress.stats.map(\.value) == Array(repeating: "0", count: 6))
        #expect(progress.stats.map(\.label) == ["Grapes", "Regions", "Lessons", "XP", "Bottles", "Certificates"])
        #expect(progress.suggestionTitle == "What Wine Is")
        #expect(progress.suggestionNote == "5 lessons · 15 min")
        #expect(progress.cta == "Start the course")
    }

    // MARK: YOU-R09, R10, R13 · Map

    @Test func YOU_R10_onlyTheQuiz_hasOneSnapshotAndNoComparison() async throws {
        let map = try #require(await make().mapModel)
        #expect(map.snapshots.count == 1)
        #expect(map.snapshots.first?.detail == "First map · 0 wines rated")
        #expect(map.comparison == nil)
        #expect(!map.showsOverTime)
    }

    @Test func YOU_R10_afterARating_comparesTheFirstMapWithToday() async throws {
        let rated = MapChange(date: .now, cause: .rating(wineKey: "w", verdict: .yes), values: [.acidity: 7, .fruit: 7, .body: 5, .sweetness: 1])
        let viewModel = await make(history: [quiz, rated])
        viewModel.selectSnapshot(0)
        let map = try #require(viewModel.mapModel)
        #expect(map.snapshots.map(\.detail) == ["First map · 0 wines rated", "Today · 1 wines rated"])
        #expect(map.deltas.first { $0.name == "Fruit" }?.delta == "+1.0")
        #expect(map.deltas.first { $0.name == "Oak" }?.delta == "—")
        #expect(map.lastChange == "Your last wine raised your fruit.")
        #expect(map.showsOverTime)
    }

    @Test func YOU_R10_aRedoneQuizWithoutRatings_hidesOverTime() async throws {
        let redo = MapChange(date: .now, cause: .quiz, values: [.acidity: 3, .fruit: 8])
        let map = try #require(await make(history: [quiz, redo]).mapModel)
        #expect(!map.showsOverTime)
    }

    @Test func YOU_R13_redo_opensTheQuiz() async {
        let actions = Actions()
        let viewModel = await make(actions: actions)
        viewModel.redoMap()
        #expect(actions.log == ["redo"])
    }

    @Test func YOU_R12_shareLink_usesTheIDNotTheName() async {
        let message = await make().shareMessage
        #expect(message.contains("uvva.app/invite/u1"))
    }

    // MARK: YOU-R14, R15 · Conta

    @Test func YOU_R14_settings_rows() async {
        let settings = await make().settings
        #expect(settings.name == "Elisa")
        #expect(settings.signedInWith == "Apple")
        #expect(settings.phone == "+351 912 345 678")
        #expect(settings.reminder == "Set a time")
    }

    @Test func YOU_R15_oneLetterName_isRefused() async {
        let profiles = ProfilesSpy(elisa)
        let viewModel = await make(profiles: profiles)
        #expect(await viewModel.saveName(" E ") == false)
        #expect(await viewModel.saveName(" Lisa ") == true)
        #expect(profiles.profile?.firstName == "Lisa")
    }

    @Test func YOU_R15_newPhone_swapsTheContactKey() async throws {
        let social = SocialSpy()
        let profiles = ProfilesSpy(elisa)
        let viewModel = await make(profiles: profiles, social: social)
        #expect(await viewModel.savePhone(national: "912000000", country: PhoneCountries.country(region: "PT")!))
        try await Task.sleep(for: .milliseconds(50))
        #expect(profiles.profile?.phone == "+351912000000")
        #expect(social.calls.contains("key-+351912345678"))
        #expect(social.calls.contains("key++351912000000"))
    }

    @Test func YOU_R15_emptyPhone_removesTheNumberAndItsKey() async throws {
        let social = SocialSpy()
        let profiles = ProfilesSpy(elisa)
        let viewModel = await make(profiles: profiles, social: social)
        #expect(await viewModel.savePhone(national: "", country: PhoneCountries.country(region: "PT")!))
        try await Task.sleep(for: .milliseconds(50))
        #expect(profiles.profile?.phone == nil)
        #expect(social.calls == ["key-+351912345678"])
    }

    // MARK: YOU-R18 to R20 · Lembrete

    @Test func YOU_R20_firstReminder_asksPermission_andSchedules() async {
        let reminders = RemindersSpy()
        let viewModel = await make(reminders: reminders)
        await viewModel.saveReminder(Reminder(hour: 19, weekdays: [2, 4, 6]))
        #expect(reminders.permissionRequests == 1)
        #expect(reminders.scheduled == [Reminder(hour: 19, weekdays: [2, 4, 6])])
        #expect(viewModel.settings.reminder == "19:00")
        await viewModel.saveReminder(nil)
        #expect(reminders.scheduled.last == .some(nil))
        #expect(viewModel.settings.reminder == "Set a time")
    }

    // MARK: YOU-R22 · Mapa público

    @Test func YOU_R22_mapPublic_isTheDefault_andTurningItOffHidesTheMap() async throws {
        let social = SocialSpy()
        let viewModel = await make(social: social)
        #expect(viewModel.settings.mapVisibility == "Public")
        await viewModel.setMapPublic(false)
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.settings.mapVisibility == "Friends")
        #expect(social.calls.last == "publish map:false")
    }

    // MARK: YOU-R26, R27 · Sair e apagar

    @Test func YOU_R26_signOut_cancelsTheReminder_andEndsTheSession() async {
        let reminders = RemindersSpy()
        let actions = Actions()
        let viewModel = await make(reminders: reminders, actions: actions)
        await viewModel.signOut()
        #expect(reminders.scheduled == [nil])
        #expect(actions.log == ["signOut"])
    }

    @Test func YOU_R27_delete_removesPublicAndPrivateData() async {
        let social = SocialSpy()
        let profiles = ProfilesSpy(elisa)
        let actions = Actions()
        let viewModel = await make(profiles: profiles, social: social, actions: actions)
        await viewModel.deleteAccount()
        #expect(social.calls == ["delete u1"])
        #expect(profiles.deleted)
        #expect(actions.log == ["deleted"])
    }

    @Test func YOU_R27_offline_keepsEverything_andSaysSo() async {
        let profiles = ProfilesSpy(elisa)
        let actions = Actions()
        let viewModel = await make(profiles: profiles, social: SocialSpy(failsDeleting: true), actions: actions)
        await viewModel.deleteAccount()
        #expect(!profiles.deleted)
        #expect(actions.log.isEmpty)
        #expect(viewModel.notice != nil)
    }
}
