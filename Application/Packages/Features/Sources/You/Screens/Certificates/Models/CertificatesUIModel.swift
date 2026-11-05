import Core
import Foundation
import DesignSystem
import SwiftUI

public struct CertificatesUIModel {
    var rows: [CertificateRowUIModel] = []
    var emptyIllustration: Image { UVVAIllustration.grape(3) }
    var certificatesText = String(localized: "Certificates", bundle: .module)
    var noCertificatesYetText = String(localized: "No certificates yet", bundle: .module)
    var startLearningText = String(localized: "Start learning", bundle: .module)
    var certificatesForTheLessonsYouText = String(localized: "Certificates for the lessons you complete live here. Finish one to see it, then come back whenever you like.", bundle: .module)
}
