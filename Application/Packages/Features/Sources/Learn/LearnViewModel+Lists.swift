import Core
import Foundation

/// The three lists of the Learn tab, ready to draw (LEARN.md §3).
extension LearnViewModel {
    static let levels = ["Essentials", "Intermediate", "Advanced", "Expert"]

    // MARK: The path (LEARN-R10)

    var pathFilters: [FilterUIModel] {
        [FilterUIModel(id: "all", label: String(localized: "All", bundle: .module), isSelected: pathLevel == nil)]
            + Self.levels.map { FilterUIModel(id: $0, label: $0, isSelected: pathLevel == $0) }
    }

    var pathGroups: [CourseGroupUIModel] {
        let shown = (courses[.path] ?? []).filter { pathLevel == nil || $0.level == pathLevel }
        return [CourseGroupUIModel(id: "path", title: nil, rows: shown.map(row))]
    }

    // MARK: By grape (LEARN-R08)

    /// All, Red, White, then the countries with the most grapes first.
    var grapeFilters: [FilterUIModel] {
        let counts = (courses[.grape] ?? []).flatMap(\.countries).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        let countries = counts.keys.sorted { (counts[$0]!, $1) > (counts[$1]!, $0) }
        let filters: [(GrapeFilter, String)] = [(.all, String(localized: "All", bundle: .module)),
                                                (.red, String(localized: "Red", bundle: .module)),
                                                (.white, String(localized: "White", bundle: .module))]
            + countries.map { (GrapeFilter.country($0), $0) }
        return filters.map { FilterUIModel(id: $0.0.id, label: $0.1, isSelected: $0.0 == grapeFilter) }
    }

    func selectGrapeFilter(id: String) {
        switch id {
        case "all": selectGrapeFilter(.all)
        case "red": selectGrapeFilter(.red)
        case "white": selectGrapeFilter(.white)
        default: selectGrapeFilter(.country(String(id.dropFirst("country-".count))))
        }
    }

    /// Reds darkest first, then whites deepest first: the order of the content (LEARN-R08).
    var grapeGroups: [CourseGroupUIModel] {
        let shown = Self.grapes(courses[.grape] ?? [], filter: grapeFilter)
        return [("red", String(localized: "Reds", bundle: .module)), ("white", String(localized: "Whites", bundle: .module))]
            .map { color, title in
                CourseGroupUIModel(id: color, title: title, rows: shown.filter { $0.color == color }.map(row))
            }
            .filter { !$0.rows.isEmpty }
    }

    static func grapes(_ grapes: [Course], filter: GrapeFilter) -> [Course] {
        grapes.filter { grape in
            switch filter {
            case .all: true
            case .red: grape.color == "red"
            case .white: grape.color == "white"
            case let .country(name): grape.countries.contains(name)
            }
        }
        .sorted { $0.order < $1.order }
    }

    // MARK: By region (LEARN-R05, R06)

    var countryFilters: [FilterUIModel] {
        countries.map { FilterUIModel(id: $0, label: $0, isSelected: $0 == country) }
    }

    var regionGroups: [CourseGroupUIModel] {
        let shown = (courses[.region] ?? []).filter { $0.countries.first == country }
        let picked = shown.filter { $0.id == pickedRegion }
        return [CourseGroupUIModel(id: "region", title: nil, rows: (picked + shown.filter { $0.id != pickedRegion }).map(row))]
    }

    /// The chosen country with its regions pinned; the open one is the larger dot.
    var regionMap: RegionMapUIModel? {
        let atlas = RegionAtlas.shared
        guard let country, let shape = atlas.country(country) else { return nil }
        let pins = (courses[.region] ?? []).filter { $0.countries.first == country }.compactMap { course -> RegionPinUIModel? in
            guard let place = atlas.regions[course.id], place.count == 2 else { return nil }
            return RegionPinUIModel(id: course.id, name: course.title, lon: place[0], lat: place[1],
                                    isSelected: openCourses[.region] == course.id, isInset: atlas.insets.contains(course.id))
        }
        return RegionMapUIModel(country: shape, pins: pins)
    }

    // MARK: Rows

    func row(_ course: Course) -> CourseRowUIModel {
        let state = CourseRules.state(of: course, progress: progress)
        return CourseRowUIModel(
            id: course.id,
            title: course.title,
            meta: Self.meta(course),
            state: state,
            isOpen: openCourses[course.kind] == course.id,
            about: course.about,
            grapes: course.kind == .region ? course.grapes : [],
            cta: Self.cta(state),
            hasCertificate: certificates.contains { $0.courseID == course.id }
        )
    }

    /// LEARN-R10a: "6 lessons · 31 min · 90 XP".
    static func meta(_ course: Course) -> String {
        String(localized: "\(course.lessons.count) lessons · \(course.minutes) min · \(course.xp) XP", bundle: .module)
    }

    /// LEARN-R11
    static func cta(_ state: CourseState) -> String {
        switch state {
        case .notStarted: String(localized: "Go to the module", bundle: .module)
        case .inProgress: String(localized: "Continue where you left off", bundle: .module)
        case .done: String(localized: "Review the module", bundle: .module)
        }
    }
}
