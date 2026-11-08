import DesignSystem
import SwiftUI

/// UVVA's reading: a line on the wine, its structure in dots and its aromas (CELLAR-R26).
struct NoteReading: View {
    var resources: NoteResourcesUIModel
    var text: String?
    var structure: [NoteStructureUIModel]
    var aromas: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NoteEyebrow(text: resources.readingText)
            if let text {
                Text(text)
                    .font(UVVAFont.sans(15))
                    .lineSpacing(5)
                    .padding(.top, 18)
            }
            VStack(spacing: 22) {
                ForEach(structure) { row in
                    HStack(spacing: 14) {
                        Text(row.label)
                            .font(UVVAFont.sans(11.5))
                            .opacity(0.72)
                            .frame(width: 70, alignment: .leading)
                        HStack(spacing: 5) {
                            ForEach(0..<NoteStructureUIModel.dotCount, id: \.self) { index in
                                if index < row.filled {
                                    Circle().fill(NotePalette.ink.opacity(0.85)).frame(width: 4, height: 4)
                                } else {
                                    Circle().strokeBorder(NotePalette.ink.opacity(0.3), lineWidth: 0.5).frame(width: 4, height: 4)
                                }
                            }
                        }
                        .accessibilityHidden(true)
                        Text(row.word)
                            .font(UVVAFont.sans(11))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 24)
            if let aromas {
                Text(aromas)
                    .font(UVVAFont.sans(12))
                    .lineSpacing(4)
                    .opacity(0.72)
                    .padding(.top, 24)
            }
        }
        .foregroundStyle(NotePalette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
