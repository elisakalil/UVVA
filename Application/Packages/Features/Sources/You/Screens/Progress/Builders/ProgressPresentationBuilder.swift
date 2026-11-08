import Core
import Foundation

struct ProgressPresentationBuilder {
    func build(from content: YouContentModel) -> ProgressUIModel {
        let lessons = content.lessons
        let certificates = Dictionary(grouping: content.certificates, by: \.courseID).compactMap { $0.value.first }
        let recommendation = content.recommendation
        let completed = lessons.values.filter(\.isCompleted)
        let stats = [
            stat(label: String(localized: "Grapes", bundle: .module), certificates: certificates.filter { $0.kind == .grape }, content: content),
            stat(label: String(localized: "Regions", bundle: .module), certificates: certificates.filter { $0.kind == .region }, content: content),
            stat(label: String(localized: "Modules", bundle: .module), certificates: certificates, content: content),
            ProgressStat(value: "\(completed.reduce(0) { $0 + $1.xp })", label: String(localized: "XP", bundle: .module)),
            ProgressStat(value: "0", label: String(localized: "Bottles", bundle: .module)),
            ProgressStat(value: "\(certificates.count)", label: String(localized: "Certificates", bundle: .module))
        ]
        let module = recommendation?.course
        return ProgressUIModel(
            stats: stats,
            specialist: SpecialistReading().text(
                completed: certificates.compactMap { content.certificateCourses[$0.courseID] },
                regionCatalog: content.regionCatalog
            ),
            suggestionEyebrow: String(localized: "A course for you", bundle: .module),
            suggestionTitle: module?.title ?? "",
            suggestionNote: module.map { String(localized: "\($0.lessonCount) lessons · \($0.minutes) min", bundle: .module) } ?? "",
            suggestionStatusMessage: recommendation == nil ? emptySuggestion(content.recommendationStatus) : nil,
            suggestedCourseID: module?.id,
            cta: module != nil ? String(localized: "Start the course", bundle: .module)
                : (content.recommendationStatus == .unavailable ? String(localized: "Explore Learn", bundle: .module) : nil)
        )
    }

    private func emptySuggestion(_ status: YouContentModel.RecommendationStatus) -> String? {
        switch status {
        case .loading: nil
        case .ready: String(localized: "There are no new course suggestions right now.", bundle: .module)
        case .unavailable: String(localized: "Your course suggestion is temporarily unavailable.", bundle: .module)
        }
    }

    private func stat(label: String, certificates: [Certificate], content: YouContentModel) -> ProgressStat {
        let items: [ProgressStatItem] = certificates.map { certificate -> ProgressStatItem in
            let course = content.certificateCourses[certificate.courseID]
            let countries = course?.countries ?? []
            let group: String
            var chips: [String]
            switch certificate.kind {
            case .grape:
                switch course?.color {
                case "red": group = String(localized: "Red grapes", bundle: .module)
                case "white": group = String(localized: "White grapes", bundle: .module)
                default: group = String(localized: "Grapes", bundle: .module)
                }
                chips = countries
            case .region:
                group = countries.first ?? String(localized: "Regions", bundle: .module)
                chips = course?.grapes ?? []
            case .path:
                group = String(localized: "The Path", bundle: .module)
                chips = [course?.level].compactMap { $0 }
            case nil:
                group = String(localized: "Other modules", bundle: .module)
                chips = []
            }
            if let course, !course.lessons.isEmpty {
                chips.append(String(localized: "\(course.lessons.count) lessons · \(course.minutes) min", bundle: .module))
            }
            return ProgressStatItem(id: certificate.courseID, title: course?.title ?? certificate.courseID,
                                    detail: course?.about ?? "", group: group, chips: chips)
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        return ProgressStat(value: "\(items.count)", label: label, items: items)
    }
}
