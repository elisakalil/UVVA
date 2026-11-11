import DesignSystem
import SwiftUI

/// Certificates (YOU-R23 to R25): the ones earned, newest first, each opening its share. Settings opens it only when
/// there is at least one (YOU-R24).
struct CertificatesView<ViewModel: CertificatesViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var onClose: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            CertificateBackground().ignoresSafeArea()
            gallery
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
}
