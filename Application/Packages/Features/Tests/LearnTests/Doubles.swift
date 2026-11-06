import Core
import Foundation
import Synchronization

struct CatalogStub: CourseCatalog {
    var all: [Course]
    var lessons: [String: Lesson]

    func courses(_ kind: CourseKind) async throws -> [Course] { all.filter { $0.kind == kind } }
    func course(id: String) async throws -> Course? { all.first { $0.id == id } }
    func lesson(id: String) async throws -> Lesson? { lessons[id] }
}

final class LearningSpy: LearningRepository {
    func snapshot(for courses: [Course]) async throws -> LearningSnapshot { testSnapshot(courses, lessons: saved) }
    func save(_ progress: LessonProgress, in course: Course) async throws { try await save(progress) }

    private let state = Mutex<(progress: [String: LessonProgress], certificates: [Certificate])>(([:], []))
    init(_ progress: [LessonProgress] = []) {
        state.withLock { $0.progress = Dictionary(uniqueKeysWithValues: progress.map { ($0.lessonID, $0) }) }
    }
    var saved: [String: LessonProgress] { state.withLock { $0.progress } }
    var issued: [Certificate] { state.withLock { $0.certificates } }
    func progress() async throws -> [String: LessonProgress] { saved }
    func save(_ progress: LessonProgress) async throws { state.withLock { $0.progress[progress.lessonID] = progress } }
    func certificates() async throws -> [Certificate] { issued }
    func addCertificate(_ certificate: Certificate) async throws {
        state.withLock { if !$0.certificates.contains(where: { $0.courseID == certificate.courseID }) { $0.certificates.append(certificate) } }
    }
}

struct ProfilesStub: ProfileRepository {
    func currentProfile() async throws -> Profile? { nil }
    func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile? { nil }
    func save(_ profile: Profile) async throws {}
    func markTourSeen(_ tour: String) async throws {}
    func deleteAccount() async throws {}
}

/// Content to test with: lessons of six steps, two questions each, as LESSON-R09 writes them.
enum Fixture {
    static let day = Date(timeIntervalSince1970: 1_800_000_000)

    static func steps(review: Bool = false) -> [LessonStep] {
        if review {
            return [.multipleChoice(prompt: "Q1", options: ["A", "B", "C", "D"], answer: 1, explanation: "B."),
                    .trueFalse(prompt: "Q2", answer: false, explanation: "False."),
                    .selectMultiple(prompt: "Q3", options: ["A", "B", "C", "D"], answers: [0, 1, 3], explanation: "ABD."),
                    .fillBlank(prompt: "Juice is ____.", options: ["must", "lees", "marc", "cuvée"], answer: "must", explanation: "Must."),
                    .ordering(prompt: "Q5", items: ["One", "Two", "Three", "Four"], explanation: "In order."),
                    .summary(title: "What you learned", points: ["Skill one", "Skill two", "Skill three"])]
        }
        return [.concept(title: "What", body: "Body.", highlight: "Key"),
                .concept(title: "Why", body: "Body.", highlight: nil),
                .multipleChoice(prompt: "Which?", options: ["A", "B", "C", "D"], answer: 2, explanation: "C."),
                .tip(body: "Tip."),
                .trueFalse(prompt: "True?", answer: true, explanation: "True."),
                .summary(title: "What you learned", points: ["One", "Two", "Three"])]
    }

    static func course(_ id: String, kind: CourseKind = .grape, order: Int = 1, lessons count: Int = 2, color: String? = "red",
                       countries: [String] = ["France"], level: String? = nil, minutes: [Int]? = nil) -> Course {
        Course(id: id, kind: kind, order: order, title: id.capitalized, about: "About \(id).", level: level, color: color,
               countries: countries,
               lessons: (1...count).map { n in
                   LessonSummary(id: "\(id)-l0\(n)", courseID: id, order: n, title: "Lesson \(n)", subtitle: "Sub", xp: 15,
                                 minutes: minutes?[n - 1] ?? 3, isReview: n == count, objectives: ["Do \(n)"])
               })
    }

    static func lessons(of course: Course) -> [String: Lesson] {
        Dictionary(uniqueKeysWithValues: course.lessons.map { ($0.id, Lesson(summary: $0, steps: steps(review: $0.isReview))) })
    }
}
