import DesignSystem
import SwiftUI

/// Certificates (YOU-R23 to R25): the ones earned, newest first, each opening its share. Empty until Learn awards one.
struct CertificatesView<ViewModel: CertificatesViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var onClose: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            CertificateBackground().ignoresSafeArea()
            if viewModel.uiModel.rows.isEmpty { empty } else { gallery }
            HStack(spacing: 8) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .light))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(Text("Close", bundle: .module))
                Text(viewModel.uiModel.certificatesText)
                    .font(UVVAFont.sans(12))
                    .padding(.horizontal, 18)
                    .frame(height: 40)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.leading, 14)
            .padding(.top, 12)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }

    private var gallery: some View {
        GeometryReader { geometry in
            let width = geometry.size.width / 3
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(width), spacing: 0), count: 3), spacing: 0) {
                    ForEach(viewModel.uiModel.rows) { row in
                        Button { onClose(); viewModel.open(row.id) } label: {
                            Group {
                                if let certificate = row.certificate {
                                    CertificateCard(model: certificate, format: .story, cornerRadius: 0)
                                        .scaleEffect(width / ShareFormat.story.cardSize.width, anchor: .topLeading)
                                        .frame(width: width, height: width * 16 / 9, alignment: .topLeading)
                                } else {
                                    Text(row.title)
                                        .font(UVVAFont.redGrapes(16))
                                        .padding(12)
                                        .frame(width: width, height: width * 16 / 9)
                                        .background(CertificateBackground())
                                }
                            }
                            .clipped()
                            .overlay(Rectangle().strokeBorder(UVVAColor.creamFill.opacity(0.65), lineWidth: 0.5))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(row.title), \(row.detail)")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var empty: some View {
        VStack(spacing: 0) {
            Spacer()
            viewModel.uiModel.emptyIllustration.resizable().scaledToFit().frame(width: 72, height: 100)
            Text(viewModel.uiModel.noCertificatesYetText.uppercased())
                .font(UVVAFont.redGrapes(22)).tracking(0.9).padding(.top, 24)
            Text(viewModel.uiModel.certificatesForTheLessonsYouText)
                .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.84)
                .multilineTextAlignment(.center).frame(maxWidth: 290).padding(.top, 12)
            ActionButton(viewModel.uiModel.startLearningText, action: { onClose(); viewModel.startLearning() })
                .frame(width: 220).padding(.top, 30)
            Spacer()
        }
    }
}
