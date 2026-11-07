import Core
import Foundation
import Synchronization

final class ProfilesSpy: ProfileRepository {
    private let state: Mutex<(profile: Profile?, deleted: Bool)>
    let failsSaving: Bool
    init(_ profile: Profile?, failsSaving: Bool = false) {
        state = Mutex((profile, false))
        self.failsSaving = failsSaving
    }
    var profile: Profile? { state.withLock { $0.profile } }
    var deleted: Bool { state.withLock { $0.deleted } }
    func currentProfile() async throws -> Profile? { profile }
    func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile? { profile }
    func save(_ profile: Profile) async throws {
        if failsSaving { throw URLError(.cannotWriteToFile) }
        state.withLock { $0.profile = profile }
    }
    func markTourSeen(_ tour: String) async throws {}
    func deleteAccount() async throws { state.withLock { $0 = (nil, true) } }
}

struct MapsStub: PalateMapRepository {
    var history: [MapChange]
    func currentMap() async throws -> PalateMap? { history.last.map { PalateMap($0.values) } }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { history }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {}
}

struct CatalogStub: CatalogRepository {
    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] { [] }
    func recipes() async throws -> [Recipe] { [] }
    func glossary() async throws -> [GlossaryTerm] { [] }
    func firstPathModule() async throws -> CourseSummary? {
        CourseSummary(id: "path-01", title: "What Wine Is", lessonCount: 5, minutes: 15)
    }
}

final class SocialSpy: SocialService {
    private let log = Mutex<[String]>([])
    let failsDeleting: Bool
    init(failsDeleting: Bool = false) { self.failsDeleting = failsDeleting }
    var calls: [String] { log.withLock { $0 } }
    func publishContactKey(phone: String, userID: String) async throws -> Bool { log.withLock { $0.append("key+\(phone)") }; return true }
    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile] { [:] }
    func sendFriendRequest(from: String, to: String) async throws {}
    func publish(_ profile: PublicProfile) async throws { log.withLock { $0.append("publish map:\(profile.map != nil)") } }
    func removeContactKey(phone: String) async throws { log.withLock { $0.append("key-\(phone)") } }
    func deleteAccount(userID: String, phone: String?) async throws {
        if failsDeleting { throw URLError(.notConnectedToInternet) }
        log.withLock { $0.append("delete \(userID)") }
    }
}

final class RemindersSpy: ReminderRepository, ReminderScheduling {
    private let state = Mutex<(saved: Reminder?, scheduled: [Reminder?], asked: Int)>((nil, [], 0))
    let failsSaving: Bool
    init(failsSaving: Bool = false) { self.failsSaving = failsSaving }
    var scheduled: [Reminder?] { state.withLock { $0.scheduled } }
    var permissionRequests: Int { state.withLock { $0.asked } }
    func reminder() async throws -> Reminder? { state.withLock { $0.saved } }
    func save(_ reminder: Reminder?) async throws {
        if failsSaving { throw URLError(.cannotWriteToFile) }
        state.withLock { $0.saved = reminder }
    }
    func requestPermission() async -> Bool { state.withLock { $0.asked += 1 }; return true }
    func schedule(_ reminder: Reminder?) async { state.withLock { $0.scheduled.append(reminder) } }
}

struct CoursesStub: CourseCatalog {
    var catalog: [Course] = []
    func courses(_ kind: CourseKind) async throws -> [Course] { catalog.filter { $0.kind == kind } }
    func course(id: String) async throws -> Course? {
        Course(id: id, kind: CourseKind(courseID: id) ?? .path, order: 1, title: "Tannat", about: "", lessons: [])
    }
    func lesson(id: String) async throws -> Lesson? { nil }
}

struct LearningStub: LearningRepository {
    func snapshot(for courses: [Course]) async throws -> LearningSnapshot { testSnapshot(courses, lessons: try await progress()) }
    func save(_ progress: LessonProgress, in course: Course) async throws { try await save(progress) }

    var lessons: [LessonProgress] = []
    var earned: [Certificate] = []
    func progress() async throws -> [String: LessonProgress] {
        Dictionary(uniqueKeysWithValues: lessons.map { ($0.lessonID, $0) })
    }
    func save(_ progress: LessonProgress) async throws {}
    func certificates() async throws -> [Certificate] { earned }
    func addCertificate(_ certificate: Certificate) async throws {}
}
