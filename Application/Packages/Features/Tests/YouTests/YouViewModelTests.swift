import Combine
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
                      history: [MapChange]? = nil, learning: LearningStub = LearningStub(),
                      actions: Actions = Actions()) async -> YouViewModel {
        let viewModel = YouFactory(profiles: profiles ?? ProfilesSpy(elisa), maps: MapsStub(history: history ?? [quiz]),
                                     catalog: CatalogStub(), courses: CoursesStub(), learning: learning, social: social,
                                     reminders: reminders, scheduler: reminders)
            .makeViewModel(coordinator: YouCoordinator(
                                     onRedoMap: { actions.log.append("redo") }, onOpenLearn: { actions.log.append("learn") },
                                     onOpenCourse: { actions.log.append("course \($0)") },
                                     onOpenCertificate: { actions.log.append("certificate \($0)") },
                                     onSignOut: { actions.log.append("signOut") },
                                     onAccountDeleted: { actions.log.append("deleted") }))
        await viewModel.load()
        return viewModel
    }

    // MARK: YOU-R01 · Header

    @Test func YOU_R01_header_showsNameAndSignature_withoutHandle() async {
        let header = await make().uiModel.header
        #expect(header.name == "Elisa")
        #expect(header.signature == "ACIDITY · FRUIT · BODY")
        #expect(!header.name.contains("@") && !header.signature.contains("@"))
    }

    // MARK: YOU-R02, R04, R07 · Progress

    @Test func YOU_R02_opensOnProgress() async {
        #expect(await make().tab == .progress)
    }

    @Test func YOU_R04_twoGrapesOneRegion_andLessonsCountedOnce() async {
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        let learning = LearningStub(
            lessons: (1...3).map { LessonProgress(lessonID: "grape-tannat-l0\($0)", courseID: "grape-tannat", currentStep: 5,
                                                  completedAt: day, lastOpenedAt: day, xp: 15) }
                + [LessonProgress(lessonID: "path-01-l01", courseID: "path-01", currentStep: 2, lastOpenedAt: day)],
            earned: [Certificate(courseID: "grape-tannat", date: day), Certificate(courseID: "grape-malbec", date: day),
                     Certificate(courseID: "region-pt-douro", date: day)])
        let viewModel = await make(learning: learning)
        #expect(viewModel.progress.uiModel.stats.map(\.value) == ["2", "1", "3", "45", "0", "3"])
        #expect(viewModel.settings.uiModel.certificates == "3")
        #expect(viewModel.settings.certificates.uiModel.rows.map(\.title) == ["Tannat", "Tannat", "Tannat"])
    }

    @Test func YOU_R07_startTheCourse_opensThePathsFirstModule() async {
        let actions = Actions()
        await make(actions: actions).progress.startCourse()
        #expect(actions.log == ["course path-01"])
    }

    @Test func YOU_R25_aCertificate_opensItsShare() async {
        let actions = Actions()
        await make(actions: actions).settings.certificates.open("grape-tannat")
        #expect(actions.log == ["certificate grape-tannat"])
    }

    @Test func YOU_R04_R07_newUser_zeros_andThePathsFirstModule() async {
        let progress = await make().progress.uiModel
        #expect(progress.stats.map(\.value) == Array(repeating: "0", count: 6))
        #expect(progress.stats.map(\.label) == ["Grapes", "Regions", "Lessons", "XP", "Bottles", "Certificates"])
        #expect(progress.suggestionTitle == "What Wine Is")
        #expect(progress.suggestionNote == "5 lessons · 15 min")
        #expect(progress.cta == "Start the course")
    }

    // MARK: YOU-R09, R10, R13 · Map

    @Test func YOU_R10_onlyTheQuiz_hasOneSnapshotAndNoComparison() async throws {
        let map = try #require(await make().map.uiModel.content)
        #expect(map.snapshots.count == 1)
        #expect(map.snapshots.first?.detail == "First map · 0 wines rated")
        #expect(map.comparison == nil)
        #expect(!map.showsOverTime)
    }

    @Test func YOU_R10_afterARating_comparesTheFirstMapWithToday() async throws {
        let rated = MapChange(date: .now, cause: .rating(wineKey: "w", verdict: .yes), values: [.acidity: 7, .fruit: 7, .body: 5, .sweetness: 1])
        let viewModel = await make(history: [quiz, rated])
        viewModel.map.selectSnapshot(0)
        let map = try #require(viewModel.map.uiModel.content)
        #expect(map.snapshots.map(\.detail) == ["First map · 0 wines rated", "Today · 1 wines rated"])
        #expect(map.deltas.first { $0.name == "Fruit" }?.delta == "+1.0")
        #expect(map.deltas.first { $0.name == "Oak" }?.delta == "—")
        #expect(map.lastChange == "Your last wine raised your fruit.")
        #expect(map.showsOverTime)
    }

    @Test func YOU_R10_aRedoneQuizWithoutRatings_hidesOverTime() async throws {
        let redo = MapChange(date: .now, cause: .quiz, values: [.acidity: 3, .fruit: 8])
        let map = try #require(await make(history: [quiz, redo]).map.uiModel.content)
        #expect(!map.showsOverTime)
    }

    @Test func YOU_R13_redo_opensTheQuiz() async {
        let actions = Actions()
        let viewModel = await make(actions: actions)
        viewModel.map.redoMap()
        #expect(actions.log == ["redo"])
    }

    @Test func YOU_R12_shareLink_usesTheIDNotTheName() async {
        let message = await make().map.uiModel.shareMessage
        #expect(message.contains("uvva.app/invite/u1"))
    }

    // MARK: YOU-R14, R15 · Conta

    @Test func YOU_R14_settings_rows() async {
        let settings = await make().settings.uiModel
        #expect(settings.name == "Elisa")
        #expect(settings.signedInWith == "Apple")
        #expect(settings.phone == "+351 912 345 678")
        #expect(settings.reminder == "Set a time")
    }

    @Test func YOU_R15_oneLetterName_isRefused() async {
        let profiles = ProfilesSpy(elisa)
        let viewModel = await make(profiles: profiles)
        #expect(await viewModel.settings.editName.saveName(" E ") == false)
        #expect(await viewModel.settings.editName.saveName(" Lisa ") == true)
        #expect(profiles.profile?.firstName == "Lisa")
    }

    @Test func YOU_R15_newPhone_swapsTheContactKey() async throws {
        let social = SocialSpy()
        let profiles = ProfilesSpy(elisa)
        let viewModel = await make(profiles: profiles, social: social)
        #expect(await viewModel.settings.editPhone.savePhone(national: "912000000", country: PhoneCountries.country(region: "PT")!))
        try await Task.sleep(for: .milliseconds(50))
        #expect(profiles.profile?.phone == "+351912000000")
        #expect(social.calls.contains("key-+351912345678"))
        #expect(social.calls.contains("key++351912000000"))
    }

    @Test func YOU_R15_emptyPhone_removesTheNumberAndItsKey() async throws {
        let social = SocialSpy()
        let profiles = ProfilesSpy(elisa)
        let viewModel = await make(profiles: profiles, social: social)
        #expect(await viewModel.settings.editPhone.savePhone(national: "", country: PhoneCountries.country(region: "PT")!))
        try await Task.sleep(for: .milliseconds(50))
        #expect(profiles.profile?.phone == nil)
        #expect(social.calls == ["key-+351912345678"])
    }

    // MARK: YOU-R18 to R20 · Lembrete

    @Test func YOU_R20_firstReminder_asksPermission_andSchedules() async {
        let reminders = RemindersSpy()
        let viewModel = await make(reminders: reminders)
        _ = await viewModel.settings.reminder.saveReminder(Reminder(hour: 19, weekdays: [2, 4, 6]))
        #expect(reminders.permissionRequests == 1)
        #expect(reminders.scheduled == [Reminder(hour: 19, weekdays: [2, 4, 6])])
        #expect(viewModel.settings.uiModel.reminder == "19:00")
        _ = await viewModel.settings.reminder.saveReminder(nil)
        #expect(reminders.scheduled.last == .some(nil))
        #expect(viewModel.settings.uiModel.reminder == "Set a time")
    }

    // MARK: YOU-R22 · Mapa público

    @Test func YOU_R22_mapPublic_isTheDefault_andTurningItOffHidesTheMap() async throws {
        let social = SocialSpy()
        let viewModel = await make(social: social)
        #expect(viewModel.settings.uiModel.mapVisibility == "Public")
        await viewModel.settings.setMapPublic(false)
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.settings.uiModel.mapVisibility == "Friends")
        #expect(social.calls.last == "publish map:false")
    }

    // MARK: YOU-R26, R27 · Sair e apagar

    @Test func YOU_R26_signOut_cancelsTheReminder_andEndsTheSession() async {
        let reminders = RemindersSpy()
        let actions = Actions()
        let viewModel = await make(reminders: reminders, actions: actions)
        await viewModel.settings.signOut()
        #expect(reminders.scheduled == [nil])
        #expect(actions.log == ["signOut"])
    }

    @Test func YOU_R27_delete_removesPublicAndPrivateData() async {
        let social = SocialSpy()
        let profiles = ProfilesSpy(elisa)
        let actions = Actions()
        let viewModel = await make(profiles: profiles, social: social, actions: actions)
        await viewModel.settings.deleteAccount()
        #expect(social.calls == ["delete u1"])
        #expect(profiles.deleted)
        #expect(actions.log == ["deleted"])
    }

    @Test func YOU_R27_offline_keepsEverything_andSaysSo() async {
        let profiles = ProfilesSpy(elisa)
        let actions = Actions()
        let viewModel = await make(profiles: profiles, social: SocialSpy(failsDeleting: true), actions: actions)
        await viewModel.settings.deleteAccount()
        #expect(!profiles.deleted)
        #expect(actions.log.isEmpty)
        #expect(viewModel.settings.uiModel.notice != nil)
    }

    @Test func savingName_updatesHeaderMapAndSettingsTogether() async {
        let viewModel = await make()
        #expect(await viewModel.settings.editName.saveName(" Lisa "))
        #expect(viewModel.uiModel.header.name == "Lisa")
        #expect(viewModel.map.uiModel.name == "Lisa")
        #expect(viewModel.settings.uiModel.name == "Lisa")
    }

    @Test func failedNameSave_keepsSharedProfileAndShowsEditorError() async {
        let profiles = ProfilesSpy(elisa, failsSaving: true)
        let viewModel = await make(profiles: profiles)
        #expect(await viewModel.settings.editName.saveName("Lisa") == false)
        #expect(viewModel.uiModel.header.name == "Elisa")
        #expect(viewModel.settings.uiModel.name == "Elisa")
        #expect(viewModel.settings.editName.uiModel.notice != nil)
        #expect(!viewModel.settings.editName.uiModel.isSaving)
    }

    @Test func failedPhoneSave_doesNotChangeThePublicContactKey() async {
        let social = SocialSpy()
        let viewModel = await make(profiles: ProfilesSpy(elisa, failsSaving: true), social: social)
        #expect(await viewModel.settings.editPhone.savePhone(national: "912000000",
                                                            country: PhoneCountries.country(region: "PT")!) == false)
        #expect(social.calls.isEmpty)
        #expect(viewModel.settings.uiModel.phone == "+351 912 345 678")
        #expect(viewModel.settings.editPhone.uiModel.notice != nil)
    }

    @Test func failedReminderSave_doesNotScheduleOrChangeSettings() async {
        let reminders = RemindersSpy(failsSaving: true)
        let viewModel = await make(reminders: reminders)
        #expect(await viewModel.settings.reminder.saveReminder(Reminder(hour: 19, weekdays: [2])) == false)
        #expect(reminders.scheduled.isEmpty)
        #expect(viewModel.settings.uiModel.reminder == "Set a time")
        #expect(viewModel.settings.reminder.uiModel.notice != nil)
        #expect(!viewModel.settings.reminder.uiModel.isSaving)
    }

    @Test func failedPublicDeletion_keepsNotificationsAndSession() async {
        let reminders = RemindersSpy()
        let profiles = ProfilesSpy(elisa)
        let actions = Actions()
        let viewModel = await make(profiles: profiles, social: SocialSpy(failsDeleting: true),
                                   reminders: reminders, actions: actions)
        await viewModel.settings.deleteAccount()
        #expect(!profiles.deleted)
        #expect(reminders.scheduled.isEmpty)
        #expect(actions.log.isEmpty)
        #expect(!viewModel.settings.uiModel.isWorking)
    }

    @Test func reopeningEditors_discardsUnsavedDrafts() async {
        let viewModel = await make()
        viewModel.settings.editName.prepare()
        viewModel.settings.editName.updateName("Unsaved")
        viewModel.settings.editName.prepare()
        #expect(viewModel.settings.editName.uiModel.name == "Elisa")
        viewModel.settings.editPhone.prepare()
        viewModel.settings.editPhone.updateNational("123")
        viewModel.settings.editPhone.prepare()
        #expect(viewModel.settings.editPhone.uiModel.national == "912345678")
    }


    @Test func profileEdit_publishesHeaderMapAndSettings() async {
        let model = await make()
        var headerNames: [String] = []
        var mapNames: [String] = []
        var settingsNames: [String] = []
        let header = model.$uiModel.sink { headerNames.append($0.header.name) }
        let map = model.map.$uiModel.sink { mapNames.append($0.name) }
        let settings = model.settings.$uiModel.sink { settingsNames.append($0.name) }
        defer { header.cancel(); map.cancel(); settings.cancel() }
        #expect(await model.settings.editName.saveName("Lisa"))
        #expect(headerNames.last == "Lisa")
        #expect(mapNames.last == "Lisa")
        #expect(settingsNames.last == "Lisa")
    }

    @Test func reminderActions_publishTheEditableDraft() async {
        let model = await make()
        let reminder = model.settings.reminder
        reminder.prepare()
        reminder.pick(.dinner)
        reminder.toggle(2)
        #expect(reminder.uiModel.draft.canSave)
        #expect(reminder.uiModel.draft.reminder == Reminder(hour: 19, weekdays: [2]))
        reminder.turnOff()
        #expect(reminder.uiModel.draft.reminder == nil)
        #expect(reminder.uiModel.draft.canSave)
    }

}
