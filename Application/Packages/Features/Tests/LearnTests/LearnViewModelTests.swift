import Core
import Foundation
import Testing
@testable import Learn

@MainActor
struct LearnViewModelTests {
    func viewModel(_ courses: [Course], learning: LearningSpy = LearningSpy()) -> LearnViewModel {
        let lessons = courses.reduce(into: [String: Lesson]()) { $0.merge(Fixture.lessons(of: $1)) { a, _ in a } }
        return LearnFactory(catalog: CatalogStub(all: courses, lessons: lessons), learning: learning,
                              profiles: ProfilesStub(), now: { Fixture.day }, pickToast: { _ in 0 }).makeViewModel()
    }

    func eventually(_ condition: () -> Bool) async {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !condition(), ContinuousClock.now < deadline { try? await Task.sleep(for: .milliseconds(5)) }
    }

    @Test func homeSuggestion_keepsRegionSelectedAfterClosingLesson() async throws {
        let first = Fixture.course("region-fr-bordeaux", kind: .region, order: 1, countries: ["France"])
        let selected = Fixture.course("region-fr-burgundy", kind: .region, order: 2, countries: ["France"])
        let model = viewModel([first, selected])
        await model.load()
        model.updateQuery("unrelated search")
        let lesson = try #require(selected.lessons.last)
        await model.openCourse(id: selected.id, lessonID: lesson.id)
        #expect(model.uiModel.query.isEmpty)
        #expect(model.uiModel.focusedCourseID == selected.id)
        #expect(model.uiModel.regionGroups.first?.rows.first?.id == selected.id)
        #expect(model.uiModel.regionMap?.pins.first(where: { $0.id == selected.id })?.isSelected == true)
        let player = try #require(model.player)
        player.close()
        await eventually { model.player == nil }
        #expect(model.uiModel.regionGroups.first?.rows.first?.isOpen == true)
        #expect(model.uiModel.focusedCourseID == selected.id)
    }

    @Test func immediateReopenFromSuggestionAndSearch_resumesSavedStep() async throws {
        let course = Fixture.course("grape-tannat")
        let model = viewModel([course])
        let lessonID = course.lessons[0].id
        await model.openCourse(id: course.id, lessonID: lessonID)
        let original = try #require(model.player)
        original.begin()
        original.primary()
        original.primary()
        original.close()
        await model.openCourse(id: course.id, lessonID: lessonID)
        let resumed = try #require(model.player)
        #expect(resumed.stepIndex == 2)
        resumed.close()
        await model.openLesson(course, lessonID: lessonID)
        #expect(model.player?.stepIndex == 2)
    }

    @Test func staleLearnCache_doesNotOverrideRepositoryProgress() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = LearningSpy()
        let model = viewModel([course], learning: learning)
        await model.load()
        let lessonID = course.lessons[0].id
        try await learning.save(LessonProgress(lessonID: lessonID, courseID: course.id, currentStep: 4,
                                               answers: [2: .options([2])], lastOpenedAt: Fixture.day))
        await model.openCourse(id: course.id, lessonID: lessonID)
        #expect(model.player?.stepIndex == 4)
        #expect(model.player?.draft(2).isChecked == true)
    }

    // MARK: LEARN-R03 · Percursos

    @Test func LEARN_R03_opensOnByRegion() {
        #expect(viewModel([]).tab == .region)
    }

    // MARK: LEARN-R05, R06 · Países e regiões

    @Test func LEARN_R06_aCountry_opensItsFirstRegion_oneAtATime() async throws {
        let regions = [Fixture.course("region-fr-bordeaux", kind: .region, order: 1, countries: ["France"]),
                       Fixture.course("region-fr-burgundy", kind: .region, order: 2, countries: ["France"]),
                       Fixture.course("region-pt-douro", kind: .region, order: 3, countries: ["Portugal"])]
        let model = viewModel(regions)
        await model.load()
        #expect(model.countries == ["France", "Portugal"])
        #expect(model.regionGroups[0].rows.filter(\.isOpen).map(\.id) == ["region-fr-bordeaux"])
        model.selectCountry("Portugal")
        #expect(model.regionGroups[0].rows.map(\.id) == ["region-pt-douro"])
        #expect(model.regionGroups[0].rows.first?.isOpen == true)
        model.selectCountry("France")
        model.toggle("region-fr-burgundy")
        #expect(model.regionGroups[0].rows.filter(\.isOpen).map(\.id) == ["region-fr-burgundy"])
    }

    @Test func LEARN_R06_theMap_pinsTheCountrysRegions_theOpenOneSelected() async throws {
        let regions = [Fixture.course("region-fr-bordeaux", kind: .region, order: 1, countries: ["France"]),
                       Fixture.course("region-fr-burgundy", kind: .region, order: 2, countries: ["France"]),
                       Fixture.course("region-pt-madeira", kind: .region, order: 3, countries: ["Portugal"])]
        let model = viewModel(regions)
        await model.load()
        #expect(model.regionMap?.country.name == "France")
        #expect(model.regionMap?.pins.map(\.id) == ["region-fr-bordeaux", "region-fr-burgundy"])
        #expect(model.regionMap?.pins.filter(\.isSelected).map(\.id) == ["region-fr-bordeaux"])
        model.selectRegion("region-fr-burgundy")
        model.selectRegion("region-fr-burgundy")
        #expect(model.regionMap?.pins.filter(\.isSelected).map(\.id) == ["region-fr-burgundy"])
        #expect(model.regionGroups[0].rows.filter(\.isOpen).map(\.id) == ["region-fr-burgundy"])
        model.selectCountry("Portugal")
        #expect(model.regionMap?.pins.first?.isInset == true)
    }

    @Test func LEARN_R06_aRegionTappedOnTheMap_leadsTheList() async throws {
        let regions = [Fixture.course("region-fr-bordeaux", kind: .region, order: 1, countries: ["France"]),
                       Fixture.course("region-fr-burgundy", kind: .region, order: 2, countries: ["France"]),
                       Fixture.course("region-fr-alsace", kind: .region, order: 3, countries: ["France"])]
        let model = viewModel(regions)
        await model.load()
        model.selectRegion("region-fr-alsace")
        #expect(model.regionGroups[0].rows.map(\.id) == ["region-fr-alsace", "region-fr-bordeaux", "region-fr-burgundy"])
        // Opening one from the list leaves the order alone.
        model.toggle("region-fr-burgundy")
        #expect(model.regionGroups[0].rows.map(\.id) == ["region-fr-alsace", "region-fr-bordeaux", "region-fr-burgundy"])
        // Another country starts in its own order.
        model.selectCountry("France")
        #expect(model.regionGroups[0].rows.map(\.id) == ["region-fr-bordeaux", "region-fr-burgundy", "region-fr-alsace"])
    }

    /// Every region course has a place, inside the frame of its country's map unless drawn in an inset.
    @Test func LEARN_R06_everyRegion_sitsInsideItsCountrysMap() throws {
        let atlas = RegionAtlas.shared
        #expect(atlas.countries.count == 15)
        #expect(atlas.regions.count == 50)
        for (id, place) in atlas.regions where !atlas.insets.contains(id) {
            let inside = atlas.countries.contains { country in
                let box = country.box
                return (box[0]...box[2]).contains(place[0]) && (box[1]...box[3]).contains(place[1])
            }
            #expect(inside, "\(id)")
        }
    }

    /// Mosel, Rheingau and Pfalz sit close together: no name covers another, nor another region's dot.
    @Test func LEARN_R06_closeRegions_namesNeverOverlap() {
        let pins = [(id: "mosel", name: "Mosel", point: CGPoint(x: 90, y: 300), isSelected: true, lon: 6.9),
                    (id: "rheingau", name: "Rheingau", point: CGPoint(x: 125, y: 297), isSelected: false, lon: 8.0),
                    (id: "pfalz", name: "Pfalz", point: CGPoint(x: 130, y: 330), isSelected: false, lon: 8.15)]
        let layout = RegionLabelLayout.place(pins, midLon: 10.45, width: 350)
        let boxes = pins.map { pin -> CGRect in
            let placement = layout[pin.id]!
            let width = RegionLabelLayout.width(of: pin.name, isSelected: pin.isSelected)
            let gap = RegionLabelLayout.gap(isSelected: pin.isSelected)
            return CGRect(x: placement.isRight ? pin.point.x + gap : pin.point.x - gap - width,
                          y: placement.y - 6, width: width, height: 12)
        }
        for (i, a) in boxes.enumerated() {
            for (j, b) in boxes.enumerated() where i < j { #expect(!a.intersects(b), "\(pins[i].id) / \(pins[j].id)") }
            for (j, pin) in pins.enumerated() where i != j {
                #expect(!a.contains(pin.point), "\(pins[i].id) covers \(pin.id)")
            }
        }
        #expect(layout["rheingau"]?.isRight == true)
    }

    @Test func mapProjection_fitsTheFrame_insideTheMargin() {
        let box = [-9.6, 36.9, -6.1, 42.2]
        let size = CGSize(width: 350, height: 430)
        let projection = MapProjection(box: box, size: size)
        let low = projection.point(lon: box[0], lat: box[1])
        let high = projection.point(lon: box[2], lat: box[3])
        #expect(low.x >= 25.9 && high.x <= 324.1 && high.y >= 25.9 && low.y <= 404.1)
        #expect(abs((low.x + high.x) / 2 - 175) < 0.01)
        // Portugal is tall: it fills the height between the margins.
        #expect(abs(low.y - high.y - 378) < 0.01)
    }

    // MARK: LEARN-R08 · Filtros

    @Test func LEARN_R08_redFilter_onlyReds_inTheirOrder() async throws {
        let grapes = [Fixture.course("grape-riesling", order: 45, color: "white", countries: ["Germany"]),
                      Fixture.course("grape-pinot-noir", order: 28, color: "red", countries: ["France"]),
                      Fixture.course("grape-tannat", order: 1, color: "red", countries: ["Uruguay", "France"])]
        let model = viewModel(grapes)
        await model.load()
        model.selectGrapeFilter(.red)
        #expect(model.grapeGroups.flatMap(\.rows).map(\.id) == ["grape-tannat", "grape-pinot-noir"])
        model.selectGrapeFilter(.country("Germany"))
        #expect(model.grapeGroups.flatMap(\.rows).map(\.id) == ["grape-riesling"])
        model.selectGrapeFilter(.all)
        #expect(model.grapeGroups.map(\.title) == ["Reds", "Whites"])
    }

    // MARK: LEARN-R10, R10a, R10b · The path

    @Test func LEARN_R10a_line_showsLessonsMinutesAndXP() {
        let module = Fixture.course("path-03", kind: .path, lessons: 6, minutes: [5, 5, 5, 5, 5, 6])
        #expect(LearnListPresentationBuilder.meta(module) == "6 lessons · 31 min · 90 XP")
    }

    @Test func LEARN_R10b_module20_opensWithModule1NotStarted() async throws {
        let model = viewModel([Fixture.course("path-01", kind: .path, order: 1), Fixture.course("path-20", kind: .path, order: 20)])
        await model.load()
        await model.startCourse(id: "path-20")
        #expect(model.player?.course.id == "path-20")
    }

    @Test func LEARN_R10_levelFilter() async throws {
        let model = viewModel([Fixture.course("path-01", kind: .path, level: "Essentials"),
                               Fixture.course("path-25", kind: .path, order: 25, level: "Expert")])
        await model.load()
        model.selectPathLevel("Expert")
        #expect(model.pathGroups[0].rows.map(\.id) == ["path-25"])
    }

    // MARK: LEARN-R11 · Rótulo e destino

    @Test func LEARN_R11_labels() {
        #expect(LearnListPresentationBuilder.cta(.notStarted) == "Start")
        #expect(LearnListPresentationBuilder.cta(.inProgress) == "Continue")
        #expect(LearnListPresentationBuilder.cta(.done) == "Review")
    }

    @Test func LEARN_R11_inProgress_opensTheSavedStep() async throws {
        let course = Fixture.course("grape-tannat", lessons: 3)
        let learning = LearningSpy([
            LessonProgress(lessonID: "grape-tannat-l01", courseID: course.id, currentStep: 5, completedAt: Fixture.day,
                           lastOpenedAt: Fixture.day, xp: 15),
            LessonProgress(lessonID: "grape-tannat-l02", courseID: course.id, currentStep: 3, lastOpenedAt: Fixture.day)
        ])
        let model = viewModel([course], learning: learning)
        await model.load()
        #expect(model.grapeGroups[0].rows[0].cta == "Continue")
        await model.openCourse(id: "grape-tannat")
        #expect(model.tab == .grape)
        #expect(model.player?.lesson.id == "grape-tannat-l02")
        #expect(model.player?.stepIndex == 3)
    }

    // MARK: LEARN-R22 · Certificado

    @Test func LEARN_R22_finishingTheLastLesson_issuesOneCertificate_andShowsIt() async throws {
        let course = Fixture.course("grape-tannat", lessons: 2)
        let learning = LearningSpy([LessonProgress(lessonID: "grape-tannat-l01", courseID: course.id, currentStep: 5,
                                                   completedAt: Fixture.day, lastOpenedAt: Fixture.day, xp: 15)])
        let model = viewModel([course], learning: learning)
        await model.load()
        await model.openCourse(id: "grape-tannat")
        let player = try! #require(model.player)
        #expect(player.lesson.id == "grape-tannat-l02")
        player.begin()
        for _ in 0..<12 where player.stepIndex != 5 {
            if case .button(_, false) = player.footer, let index = player.stepIndex {
                if case .fillBlank = player.lesson.steps[index] { player.tapWord("must") } else { player.tapOption(0) }
            }
            player.primary()
        }
        try await player.saveOnExit()
        #expect(learning.issued == [Certificate(courseID: "grape-tannat", date: Fixture.day)])
        player.primary() // "Finish module"
        await eventually { player.certificate != nil }
        #expect(player.certificate?.title == "Grape-Tannat")
        #expect(player.certificate?.skills == ["Skill one", "Skill two", "Skill three"])
        #expect(player.certificate?.xp == "+30 XP")
        #expect(model.grapeGroups[0].rows[0].hasCertificate)
    }

    @Test func LEARN_R22_reviewedAndFinishedAgain_noNewCertificate() async throws {
        let course = Fixture.course("grape-tannat", lessons: 2)
        let done = course.lessons.map {
            LessonProgress(lessonID: $0.id, courseID: course.id, currentStep: 5, completedAt: Fixture.day, lastOpenedAt: Fixture.day, xp: 15)
        }
        let learning = LearningSpy(done)
        try? await learning.addCertificate(Certificate(courseID: course.id, date: Fixture.day))
        let model = viewModel([course], learning: learning)
        await model.load()
        #expect(model.grapeGroups[0].rows[0].cta == "Review")
        await model.openCourse(id: "grape-tannat")
        #expect(model.player?.lesson.id == "grape-tannat-l01")
        #expect(model.player?.stepIndex == 5)
        #expect(model.player?.isReview == true)
        #expect(learning.issued.count == 1)
    }

    // MARK: LEARN-R14 · Voltar entre lições

    @Test func LEARN_R14_aLessonOpenedFromAnother_backReturnsToIt_thenLeaves() async throws {
        let course = Fixture.course("grape-tannat", lessons: 2)
        let learning = LearningSpy([LessonProgress(lessonID: "grape-tannat-l01", courseID: course.id, currentStep: 5,
                                                   lastOpenedAt: Fixture.day)])
        let model = viewModel([course], learning: learning)
        await model.load()
        await model.openCourse(id: "grape-tannat")
        let first = try #require(model.player)
        #expect(first.lesson.id == "grape-tannat-l01")
        await eventually { first.hasSavedSummary && !model.uiModel.isLoadingLesson }
        first.primary()
        await eventually { model.players.count == 2 }
        #expect(model.player?.lesson.id == "grape-tannat-l02")
        model.player?.back()
        await eventually { model.players.count == 1 }
        await eventually { model.player?.lesson.id == first.lesson.id && !model.uiModel.isLoadingLesson }
        #expect(model.player?.lesson.id == first.lesson.id)
        #expect(model.player?.playerState == .step(5))
        model.player?.back()
        await eventually { model.player == nil }
    }
}
