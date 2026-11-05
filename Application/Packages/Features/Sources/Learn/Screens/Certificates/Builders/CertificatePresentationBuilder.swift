import Core
import DesignSystem
import Foundation

struct CertificatePresentationBuilder {
    static func certificate(course: Course, date: Date, skills: [String], firstName: String) -> CertificateUIModel {
        CertificateUIModel(
            date: date.formatted(.dateTime.day().month(.abbreviated).year()),
            kind: kindLabel(course.kind),
            lead: firstName.isEmpty ? String(localized: "Now I know", bundle: .module)
                : String(localized: "\(firstName) now knows", bundle: .module),
            title: course.title,
            about: course.about,
            skills: Array(skills.prefix(3)),
            xp: "+\(course.xp) XP",
            message: String(localized: "I just finished \(course.title) on UVVA.", bundle: .module)
        )
    }

    static func kindLabel(_ kind: CourseKind) -> String {
        switch kind {
        case .path: String(localized: "Module", bundle: .module)
        case .grape: String(localized: "Grape", bundle: .module)
        case .region: String(localized: "Region", bundle: .module)
        }
    }
}
