import Core
import Foundation

struct CertificatesPresentationBuilder {
    func build(from content: YouContent) -> [CertificateRowUIModel] {
        content.certificates.map { certificate in
            let kind = switch certificate.kind {
            case .grape: String(localized: "Grape", bundle: .module)
            case .region: String(localized: "Region", bundle: .module)
            case .path, nil: String(localized: "Module", bundle: .module)
            }
            return CertificateRowUIModel(id: certificate.courseID,
                                         title: content.certificateCourses[certificate.courseID]?.title ?? certificate.courseID,
                                         detail: "\(kind) · \(certificate.date.formatted(.dateTime.day().month(.abbreviated).year()))")
        }
    }

}
