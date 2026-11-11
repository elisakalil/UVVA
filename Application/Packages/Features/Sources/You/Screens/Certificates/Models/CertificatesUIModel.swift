import Core
import Foundation

public struct CertificatesUIModel {
    var rows: [CertificateRowUIModel] = []
    var certificatesText = String(localized: "Certificates", bundle: .module)
}
