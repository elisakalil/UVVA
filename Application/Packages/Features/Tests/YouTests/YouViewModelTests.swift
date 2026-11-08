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
                      actions: Actions = Actions(), courses: CoursesStub = CoursesStub()) async -> YouViewModel {
        let viewModel = YouFactory(profiles: profiles ?? ProfilesSpy(elisa), maps: MapsStub(history: history ?? [quiz]),
                                     catalog: CatalogStub(), courses: courses, learning: learning, social: social,
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
        let viewModel = await make(actions: actions)
        // Child callbacks read the parent's model; keep its owner alive as the app does.
        withExtendedLifetime(viewModel) { viewModel.progress.startCourse() }
        #expect(actions.log == ["course path-01"])
    }

    @Test func courseSuggestionOpensTheCourseShownAfterTheIntroduction() async {
        let next = Course(id: "path-02", kind: .path, order: 2, title: "Types and Styles", about: "", lessons: [])
        let actions = Actions()
        let model = await make(learning: LearningStub(earned: [Certificate(courseID: "path-01", date: .now)]),
                               actions: actions, courses: CoursesStub(catalog: [next]))
        #expect(model.progress.uiModel.suggestionTitle == next.title)
        #expect(model.progress.uiModel.suggestionStatusMessage == nil)
        model.progress.startCourse()
        #expect(actions.log == ["course path-02"])
    }

    @Test func YOU_R25_aCertificate_opensItsShare() async {
        let actions = Actions()
        await make(actions: actions).settings.certificates.open("grape-tannat")
        #expect(actions.log == ["certificate grape-tannat"])
    }

    @Test func YOU_R04_R07_newUser_zeros_andThePathsFirstModule() async {
        let progress = await make().progress.uiModel
        #expect(progress.stats.map(\.value) == Array(repeating: "0", count: 6))
        #expect(progress.stats.map(\.label) == ["Grapes", "Regions", "Modules", "XP", "Bottles", "Certificates"])
        #expect(progress.suggestionTitle == "What Wine Is")
        #expect(progress.suggestionNote == "5 lessons · 15 min")
        #expect(progress.cta == "Start the course")
    }

    @Test func progress_groupsCompletedCourses_andPersonalizesFromTheirMetadata() {
        let path = Course(id: "path-01", kind: .path, order: 1, title: "What Wine Is", about: "An introduction to wine.", level: "Essentials", lessons: [])
        let grape = Course(id: "grape-tannat", kind: .grape, order: 1, title: "Tannat", about: "", countries: ["Uruguay"], lessons: [])
        let region = Course(id: "region-uy-canelones", kind: .region, order: 1, title: "Canelones", about: "Vineyards near Montevideo.", countries: ["Uruguay"], grapes: ["Tannat"], lessons: [])
        var content = YouContentModel()
        content.certificates = [path, grape, region, grape].map { Certificate(courseID: $0.id, date: .now) }
        content.certificateCourses = [path.id: path, grape.id: grape, region.id: region]
        let model = ProgressPresentationBuilder().build(from: content)
        #expect(model.stats.prefix(3).map(\.value) == ["1", "1", "3"])
        #expect(model.stats[0].items.first?.title == "Tannat")
        #expect(model.stats[1].items.first?.detail == "Vineyards near Montevideo.")
        #expect(Set(model.stats[2].items.map(\.id)) == Set([path.id, grape.id, region.id]))
        #expect(model.stats[2].items.first { $0.id == path.id }?.detail == "An introduction to wine.")
        #expect(model.specialist.contains("beginner"))
        #expect(model.specialist.contains("Tannat"))
        #expect(model.specialist.contains("Canelones"))
    }

    @Test func specialist_connectsStudiedRegionsThroughGrapeAliases() {
        let grape = Course(id: "grape-tempranillo", kind: .grape, order: 1, title: "Tempranillo", about: "", aliases: ["Tinta Roriz"], lessons: [])
        let rioja = Course(id: "region-es-rioja", kind: .region, order: 1, title: "Rioja", about: "", countries: ["Spain"], grapes: ["Tempranillo"], lessons: [])
        let douro = Course(id: "region-pt-douro", kind: .region, order: 1, title: "Douro", about: "", countries: ["Portugal"], grapes: ["Tinta Roriz"], lessons: [])
        let reading = SpecialistReading()
        let story = reading.text(completed: [grape, rioja, douro], regionCatalog: [])
        #expect(story.contains("Tempranillo across borders"))
        #expect(story.contains("Rioja") && story.contains("Douro"))
        #expect(story == reading.text(completed: [douro, grape, rioja], regionCatalog: []))
    }

    @Test func specialist_infersARegionFromMultipleGrapes() {
        let varieties = ["Touriga Nacional", "Tinta Barroca"]
        let grapes = varieties.map { Course(id: $0, kind: .grape, order: 1, title: $0, about: "", lessons: []) }
        let douro = Course(id: "region-pt-douro", kind: .region, order: 1, title: "Douro", about: "", grapes: varieties, lessons: [])
        let story = SpecialistReading().text(completed: grapes, regionCatalog: [douro])
        #expect(story.contains("Douro"))
        #expect(varieties.allSatisfy { story.contains($0) })
    }

    // MARK: YOU-R09, R10, R13 · Map

    @Test func YOU_R10_onlyTheQuiz_hidesOverTime() async throws {
        let map = try #require(await make().map.uiModel.content)
        #expect(map.snapshots.isEmpty)
    }

    @Test func YOU_R10_afterARating_showsTheNewMapAndOnlyChangedAxes() async throws {
        let rated = MapChange(date: .now, cause: .rating(wineKey: "w", verdict: .yes),
                              values: [.acidity: 7, .fruit: 7, .body: 5, .sweetness: 0.5])
        let map = try #require(await make(history: [quiz, rated]).map.uiModel.content)
        #expect(map.snapshots.count == 1)
        let selected = try #require(map.snapshots.last)
        #expect(selected.map[.fruit] == 7)
        #expect(selected.deltas.first { $0.axis == .fruit }?.value == 1)
        #expect(selected.deltas.first { $0.axis == .sweetness }?.value == -0.5)
        #expect(selected.deltas.count == 2)
        #expect(map.lastChange == "Your last wine raised your fruit.")
    }

    @Test func YOU_R10_keepsSixDistinctMeasurementsFromTheSameDay() async throws {
        let ratings = (1...8).map { index in
            MapChange(date: quiz.date.addingTimeInterval(Double(index)), cause: .rating(wineKey: "w", verdict: .yes),
                      values: [.acidity: 7, .fruit: index == 8 ? 8 : (index.isMultiple(of: 2) ? 6 : 8),
                               .body: 5, .sweetness: 1])
        }
        let viewModel = await make(history: [quiz] + ratings)
        let latest = try #require(viewModel.map.uiModel.content)
        #expect(latest.snapshots.map(\.date) == ratings[1..<7].map(\.date))
        #expect(latest.lastChange == "Your last wine raised your fruit.")

        #expect(latest.snapshots.map { $0.map[.fruit] } == [6, 8, 6, 8, 6, 8])
        let oldest = try #require(latest.snapshots.first)
        #expect(oldest.map[.fruit] == 6)
        #expect(oldest.deltas == [MapDeltaRow(axis: .fruit, value: -2)])
    }

    @Test func YOU_R10_animatesCoordinatesAndFinishesAtTheSelectedMeasurement() {
        let start = Date(timeIntervalSince1970: 1_000)
        let from = [0.4, 0.6]
        let target = [0.405, 0.58]
        let transition = HistoryMapTransition(from: from, to: target, startedAt: start)
        let halfway = transition.values(at: start.addingTimeInterval(HistoryMapTransition.duration / 2))
        #expect(transition.values(at: start) == from)
        #expect(halfway[0] > from[0] && halfway[0] < target[0])
        #expect(halfway[1] < from[1] && halfway[1] > target[1])
        #expect(transition.values(at: start.addingTimeInterval(1)) == target)
    }

    @Test func YOU_R10_keepsSmallChangesAtTheirExactSavedValues() async throws {
        let rated = MapChange(date: quiz.date, cause: .rating(wineKey: "w", verdict: .yes),
                              values: [.acidity: 7, .fruit: 6.01, .body: 5, .sweetness: 1])
        let map = try #require(await make(history: [quiz, rated]).map.uiModel.content)
        #expect(map.snapshots.count == 1)
        #expect(map.snapshots.first?.map[.fruit] == 6.01)
    }

    @Test func YOU_R10_magnifiesSmallMovementsOnlyInTheHistoryChart() async throws {
        let ratings = [6.0, 6.27].enumerated().map { index, fruit in
            MapChange(date: quiz.date.addingTimeInterval(Double(index)), cause: .rating(wineKey: "w", verdict: .yes),
                      values: [.acidity: 7, .fruit: fruit, .body: 5, .sweetness: 1.2])
        }
        let model = try #require(await make(history: [quiz] + ratings).map.uiModel.content)
        let fruit = try #require(PalateAxis.allCases.firstIndex(of: .fruit))
        let coordinates = model.historyChartValues
        #expect(abs(coordinates[1][fruit] - coordinates[0][fruit] - 0.3) < 0.000001)
        #expect(model.snapshots.map { $0.map[.fruit] } == [6, 6.27])
    }

    @Test func YOU_R10_fitsLargeMovementsWithoutCollapsingDistinctCoordinates() async throws {
        let ratings = [4.0, 7.0, 9.0].map { fruit in
            MapChange(date: quiz.date, cause: .rating(wineKey: "w", verdict: .yes),
                      values: [.fruit: fruit])
        }
        let model = try #require(await make(history: [quiz] + ratings).map.uiModel.content)
        let fruit = try #require(PalateAxis.allCases.firstIndex(of: .fruit))
        let coordinates = model.historyChartValues.map { $0[fruit] }
        #expect(coordinates[0] >= -0.000001 && coordinates[2] <= 1.000001)
        #expect(coordinates[0] < coordinates[1] && coordinates[1] < coordinates[2])
    }

    @Test func YOU_R10_sumsSignedChangesFromOnlyTheSixVisibleMeasurements() async throws {
        let ratings = (1...7).map { index in
            MapChange(date: quiz.date.addingTimeInterval(Double(index)), cause: .rating(wineKey: "w", verdict: .yes),
                      values: [.acidity: index.isMultiple(of: 2) ? 8 : 7,
                               .fruit: index == 1 ? 8 : 7 + Double(index) * 0.04,
                               .body: 5, .sweetness: 1])
        }
        let model = try #require(await make(history: [quiz] + ratings).map.uiModel.content)
        let fruit = try #require(model.historyDeltas.first { $0.axis == .fruit })
        #expect(abs(fruit.value - (-0.72)) < 0.000001)
        #expect(model.historyDeltas.map(\.axis) == [.fruit])
    }

    @Test func YOU_R10_aRedoneQuizWithoutRatings_hidesOverTime() async throws {
        let rated = MapChange(date: quiz.date.addingTimeInterval(1), cause: .rating(wineKey: "w", verdict: .yes),
                              values: [.acidity: 7, .fruit: 7])
        let redo = MapChange(date: quiz.date.addingTimeInterval(2), cause: .quiz, values: [.acidity: 3, .fruit: 8])
        let map = try #require(await make(history: [quiz, rated, redo]).map.uiModel.content)
        #expect(map.snapshots.isEmpty)
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


    @Test func parentOwnsSavedChanges_withoutResettingAnOpenEditorDraft() async {
        let model = await make()
        model.settings.editName.prepare()
        model.settings.editName.updateName("Unsaved draft")
        let photo = Data([1, 2, 3])
        await model.settings.savePhoto(photo)
        #expect(model.contentModel.profile?.photo == photo)
        #expect(model.uiModel.header.photo == photo)
        #expect(model.settings.editName.uiModel.name == "Unsaved draft")
    }

    @Test func screenCallbacks_doNotRetainTheParent() async {
        var parent: YouViewModel? = await make()
        weak var released = parent
        let editor = parent?.settings.editName
        parent = nil
        #expect(released == nil)
        #expect(await editor?.saveName("Lisa") == false)
    }

}
