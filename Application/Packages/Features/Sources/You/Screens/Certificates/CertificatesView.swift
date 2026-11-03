import DesignSystem
import SwiftUI

/// Certificates (YOU-R23 to R25): the ones earned, newest first, each opening its share. Empty until Learn awards one.
struct CertificatesView: View {
    var rows: [CertificateRowUIModel]
    var onOpen: (String) -> Void
    var onStartLearning: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PageBackground(photoOpacity: 0.5)
            VStack(spacing: 0) {
                FlowTopBar(caption: String(localized: "Certificates", bundle: .module)) { dismiss() }
                    .padding(.horizontal, 26)
                if rows.isEmpty { empty } else { list }
            }
            .padding(.top, 8)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(String(format: "%02d", rows.count))
                    .font(UVVAFont.sans(38, .ultraLight))
                    .padding(.top, 28)
                    .padding(.bottom, 12)
                ForEach(rows) { row in
                    Button { onOpen(row.id) } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(row.title).font(UVVAFont.redGrapes(20))
                                Text(row.detail.uppercased()).font(UVVAFont.sans(9.5)).tracking(1.6).opacity(0.6)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(verbatim: "›").font(UVVAFont.sans(20, .ultraLight)).opacity(0.6)
                        }
                        .padding(.vertical, 18)
                        .overlay(alignment: .top) { Rectangle().fill(UVVAColor.creamFill.opacity(0.18)).frame(height: 0.5) }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 26)
        }
        .scrollIndicators(.hidden)
    }

    private var empty: some View {
        VStack(spacing: 0) {
            Spacer()
            UVVAIllustration.grape(3).resizable().scaledToFit().frame(width: 72, height: 100)
            Text(String(localized: "No certificates yet", bundle: .module).uppercased())
                .font(UVVAFont.redGrapes(22)).tracking(0.9).padding(.top, 24)
            Text("Certificates for the lessons you complete live here. Finish one to see it, then come back whenever you like.", bundle: .module)
                .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.84)
                .multilineTextAlignment(.center).frame(maxWidth: 290).padding(.top, 12)
            ActionButton(String(localized: "Start learning", bundle: .module), action: onStartLearning)
                .frame(width: 220).padding(.top, 30)
            Spacer()
        }
    }
}
