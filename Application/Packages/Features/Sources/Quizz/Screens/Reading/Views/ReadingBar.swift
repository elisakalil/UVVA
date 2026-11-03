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

    @State private var width: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                Capsule()
                    .fill(UVVAColor.creamFill.opacity(index == selection ? 1 : 0.16 + 0.16 * nearness(index)))
                    .frame(width: 9, height: height(index))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 92)
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        // A tap picks a bar; sliding the finger along the bar moves the choice with it.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let index = position(at: drag.location.x)
                    if index != selection { onSelect(index) }
                }
        )
        // A soft tick at each bar the finger crosses, a little firmer towards the top of the scale.
        .sensoryFeedback(trigger: selection) { _, new in
            new.map { .impact(flexibility: .soft, intensity: 0.45 + 0.055 * Double($0)) }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Position", bundle: .module))
        .accessibilityValue(selection.map { "\($0)" } ?? "")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onSelect(min(9, (selection ?? -1) + 1))
            case .decrement: onSelect(max(0, (selection ?? 1) - 1))
            @unknown default: break
            }
        }
    }

    /// The bar under a point along the row, kept within 0...9 when the finger runs past either end.
    private func position(at x: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        return min(9, max(0, Int(x / width * 10)))
    }
}
