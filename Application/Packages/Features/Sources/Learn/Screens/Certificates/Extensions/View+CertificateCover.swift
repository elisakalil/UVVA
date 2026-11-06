import DesignSystem
import SwiftUI

extension View {
    @ViewBuilder
    public func certificateCover<ViewModel: LearnViewModelProtocol>(_ learn: ViewModel?) -> some View {
        if let learn { modifier(LearnCertificateCover(viewModel: learn)) }
        else { self }
    }
}

private struct LearnCertificateCover<ViewModel: LearnViewModelProtocol>: ViewModifier {
    @ObservedObject var viewModel: ViewModel

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: Binding(
            get: { viewModel.uiModel.sharedCertificate != nil },
            set: { if !$0 { viewModel.closeCertificate() } }
        )) {
            if let certificate = viewModel.uiModel.sharedCertificate {
                ShareScreen(title: viewModel.uiModel.resources.shareWhatYouLearnedText, message: certificate.message, isCertificate: true) { format in
                    CertificateCard(model: certificate, format: format)
                } onFinish: { viewModel.closeCertificate() }
            }
        }
    }
}
