import DesignSystem
import SwiftUI

/// The colours of the lesson player: cream on wine, and the tip the other way round (artboard Lessons).
enum LessonPalette {
    static let wine = UVVAColor.burgundy
    static let ink = UVVAColor.creamFill
    static let dim = UVVAColor.creamFill.opacity(0.62)
    static let line = UVVAColor.creamFill.opacity(0.16)
    static let accent = UVVAColor.grape
    static let correct = Color(hex: 0xB5CF9C)
    static let wrong = Color(hex: 0xF3A58F)

    /// The colour of an option, a word, a row or a term in each state.
    static func tone(_ state: OptionState) -> Color {
        switch state {
        case .idle: ink
        case .selected: accent
        case .correct: correct
        case .wrong: wrong
        }
    }
}
