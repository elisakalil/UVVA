import DesignSystem
import SwiftUI

/// The bar of ten positions, 0...9 (QUIZ-R03, R10). The chosen bar stands tall and bright,
/// its neighbours rise a little; with nothing chosen every bar is low.
struct ReadingBar: View {
    var selection: Int?
    var onSelect: (Int) -> Void

    private func height(_ index: Int) -> CGFloat {
        guard let selection else { return 20 }
        if index == selection { return 88 }
        return 20 + 34 * nearness(index)
    }

    private func nearness(_ index: Int) -> CGFloat {
        guard let selection else { return 0 }
        return max(0, 1 - CGFloat(abs(index - selection)) / 3)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                Button { onSelect(index) } label: {
                    Capsule()
                        .fill(UVVAColor.creamFill.opacity(index == selection ? 1 : 0.16 + 0.16 * nearness(index)))
                        .frame(width: 9, height: height(index))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Position \(index)", bundle: .module))
                .accessibilityAddTraits(index == selection ? .isSelected : [])
            }
        }
        .frame(height: 92)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
