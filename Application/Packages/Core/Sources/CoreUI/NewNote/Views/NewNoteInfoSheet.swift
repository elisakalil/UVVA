#if os(iOS)
import DesignSystem
import SwiftUI

/// A short explanation over the note, in the same dark sheet as the chips: what "Intensity" is and that it can be set.
struct NewNoteInfoSheet: View {
    var title: String
    var paragraphs: [String]
    var resources: NewNoteResourcesUIModel

    @Environment(\.dismiss) private var dismiss
    /// The sheet is as tall as its words, at any text size.
    @State private var height: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(title.uppercased())
                    .font(UVVAFont.redGrapes(20))
                    .tracking(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: resources.closeIcon)
                        .font(.system(size: 11))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.closeText)
            }
            VStack(alignment: .leading, spacing: 14) {
                ForEach(paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(UVVAFont.sans(14))
                        .lineSpacing(5)
                        .foregroundStyle(UVVAColor.cream84)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 22)
        .padding(.bottom, 24)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .presentationBackground {
            ZStack {
                PageBackground()
                NotePalette.veil.ignoresSafeArea()
            }
        }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
#endif
