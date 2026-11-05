import Core
import Foundation

struct LearnSearchPresentationBuilder {
    let courses: [CourseKind: [Course]]
    let query: String
    static let lessonLimit = 20

    var isSearching: Bool { !Self.words(query).isEmpty }

    var searchResults: [SearchGroupUIModel] {
        let words = Self.words(query)
        guard !words.isEmpty else { return [] }
        let bands: [(CourseKind, String)] = [(.region, String(localized: "Regions", bundle: .module)),
                                             (.grape, String(localized: "Grapes", bundle: .module)),
                                             (.path, String(localized: "The path", bundle: .module))]
        var groups = bands.map { kind, title in
            let found = (courses[kind] ?? []).filter { Self.matches(words, in: Self.fields(of: $0)) }
            // Names that match come before courses found only by a country or a grape.
            let byName = found.filter { Self.matches(words, in: [$0.title]) }
            let others = found.filter { !Self.matches(words, in: [$0.title]) }
            return SearchGroupUIModel(id: kind.rawValue, title: title, results: (byName + others).map(Self.result))
        }
        let lessons = CourseKind.allCases.flatMap { courses[$0] ?? [] }.flatMap { course in
            course.lessons.filter { Self.matches(words, in: [$0.title]) }.map { lesson in
                SearchResultUIModel(
                    id: lesson.id, title: lesson.title,
                    detail: "\(course.title) · " + String(localized: "Lesson \(lesson.order)", bundle: .module),
                    target: .lesson(courseID: course.id, lessonID: lesson.id))
            }
        }
        groups.append(SearchGroupUIModel(id: "lessons", title: String(localized: "Lessons", bundle: .module),
                                         results: Array(lessons.prefix(Self.lessonLimit))))
        return groups.filter { !$0.results.isEmpty }
    }

    // MARK: Matching

    static func words(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    static func matches(_ words: [String], in fields: [String]) -> Bool {
        words.allSatisfy { word in
            fields.contains { $0.range(of: word, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }

    private static func fields(of course: Course) -> [String] {
        [course.title] + course.countries + course.grapes + [course.level].compactMap(\.self)
    }

    private static func result(_ course: Course) -> SearchResultUIModel {
        let detail: String = switch course.kind {
        case .region: course.countries.first ?? ""
        case .grape: ([course.color == "red" ? String(localized: "Red", bundle: .module) : String(localized: "White", bundle: .module)]
                      + course.countries.prefix(2)).joined(separator: " · ")
        case .path: course.level ?? ""
        }
        return SearchResultUIModel(id: course.id, title: course.title, detail: detail, target: .course(id: course.id))
    }
}
