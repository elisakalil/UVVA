import Core
import Foundation

struct ProgressPresentationBuilder {
    func build(from content: YouContent) -> ProgressUIModel {
        let lessons = content.lessons
        let certificates = content.certificates
        let firstModule = content.firstModule
        let completed = lessons.values.filter(\.isCompleted)
        let stats = [
            ProgressStat(value: "\(certificates.filter { $0.kind == .grape }.count)", label: String(localized: "Grapes", bundle: .module)),
            ProgressStat(value: "\(certificates.filter { $0.kind == .region }.count)", label: String(localized: "Regions", bundle: .module)),
            ProgressStat(value: "\(completed.count)", label: String(localized: "Lessons", bundle: .module)),
            ProgressStat(value: "\(completed.reduce(0) { $0 + $1.xp })", label: String(localized: "XP", bundle: .module)),
            ProgressStat(value: "0", label: String(localized: "Bottles", bundle: .module)),
            ProgressStat(value: "\(certificates.count)", label: String(localized: "Certificates", bundle: .module))
        ]
        let module = firstModule
        return ProgressUIModel(
            stats: stats,
            specialist: String(localized: "Nothing to map yet. Finish your first course and this space starts filling in: the grapes you know, the regions you can place, and where you are strongest.", bundle: .module),
            suggestionEyebrow: String(localized: "A course for you", bundle: .module),
            suggestionTitle: module?.title ?? "",
            suggestionNote: module.map { String(localized: "\($0.lessonCount) lessons · \($0.minutes) min", bundle: .module) } ?? "",
            cta: String(localized: "Start the course", bundle: .module)
        )
    }

}
