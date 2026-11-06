import Foundation
import DesignSystem

/// One certificate earned, in You › Certificates (YOU-R23).
struct CertificateRowUIModel: Identifiable, Equatable {
    /// The course id.
    var id: String
    var title: String
    /// "Grape · 24 Sep 2026"
    var detail: String
    var certificate: CertificateUIModel? = nil
}
