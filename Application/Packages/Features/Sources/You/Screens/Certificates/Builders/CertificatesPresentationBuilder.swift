import Core
import Foundation
import DesignSystem

struct CertificatesPresentationBuilder {
    func build(from content: YouContentModel) -> [CertificateRowUIModel] {
        content.certificates.map { certificate in
            let kind = switch certificate.kind {
            case .grape: String(localized: "Grape", bundle: .module)
            case .region: String(localized: "Region", bundle: .module)
            case .path, nil: String(localized: "Module", bundle: .module)
            }
            let course = content.certificateCourses[certificate.courseID]
            let firstName = content.profile?.firstName ?? ""
            let preview = course.map { course in
                CertificateUIModel(
                    date: certificate.date.formatted(.dateTime.day().month(.abbreviated).year()),
                    kind: kind,
                    lead: firstName.isEmpty ? String(localized: "Now I know", bundle: .module)
                        : String(localized: "\(firstName) now knows", bundle: .module),
                    title: course.title,
                    about: course.about,
                    skills: Array((course.lessons.last(where: \.isReview) ?? course.lessons.last)?.objectives.prefix(3) ?? []),
                    xp: "+\(course.xp) XP",
                    message: String(localized: "I just finished \(course.title) on UVVA.", bundle: .module),
                    country: course.kind == .region ? course.countries.first : nil,
                    courseID: course.id
                )
            }
            return CertificateRowUIModel(id: certificate.courseID,
                                         title: content.certificateCourses[certificate.courseID]?.title ?? certificate.courseID,
                                         detail: "\(kind) · \(certificate.date.formatted(.dateTime.day().month(.abbreviated).year()))",
                                         certificate: preview)
        }
    }

}
