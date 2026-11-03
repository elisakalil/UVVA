import SwiftUI

/// The square-cornered cell of ordering and matchPairs, outlined in the colour of its state.
enum PairCell {
    static func background(_ state: OptionState, pickedFill: Color) -> some View {
        let tone = LessonPalette.tone(state)
        return RoundedRectangle(cornerRadius: 2)
            .fill(state == .selected ? pickedFill : state == .idle ? .clear : tone.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 2)
                .strokeBorder(state == .idle ? LessonPalette.ink.opacity(0.25) : state == .selected ? pickedFill : tone, lineWidth: 1))
    }
}
