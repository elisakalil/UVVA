import DesignSystem
import SwiftUI

extension View {
    /// The certificate share (LEARN-R24, YOU-R25) over the whole app, so it opens from Learn and from You alike.
    public func certificateCover(_ learn: LearnViewModel?) -> some View {
        fullScreenCover(isPresented: Binding(get: { learn?.sharedCertificate != nil }, set: { if !$0 { learn?.closeCertificate() } })) {
            if let learn, let certificate = learn.sharedCertificate {
                ShareScreen(title: String(localized: "Share what you learned", bundle: .module), message: certificate.message) { format in
                    CertificateCard(model: certificate, format: format)
                } onFinish: {
                    learn.closeCertificate()
                }
            }
        }
    }
}
