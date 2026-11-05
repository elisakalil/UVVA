import Core
import DesignSystem
import SwiftUI

/// By region, By grape and The path, over a hairline; the chosen one underlined (LEARN-R03).
struct LearnTabBar: View {
    var resources = LearnResourcesUIModel()
    var selected: CourseKind
    var onSelect: (CourseKind) -> Void

    static let order: [CourseKind] = [.region, .grape, .path]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.order, id: \.self) { kind in
                let isOn = kind == selected
                Button { onSelect(kind) } label: {
                    Text(label(kind).uppercased())
                        .font(UVVAFont.sans(11))
                        .tracking(1.1)
                        .lineLimit(1)
                        .opacity(isOn ? 1 : 0.45)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(UVVAColor.creamFill.opacity(isOn ? 0.85 : 0)).frame(height: 1.5)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Color(hex: 0xE2D5BA).opacity(0.7)).frame(height: 1).offset(y: 0.5) }
    }

    func label(_ kind: CourseKind) -> String {
        switch kind {
        case .region: resources.byRegionText
        case .grape: resources.byGrapeText
        case .path: resources.thePathText
        }
    }
}
