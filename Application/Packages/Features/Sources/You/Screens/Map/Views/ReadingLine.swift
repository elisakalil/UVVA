import DesignSystem
import SwiftUI

/// An axis of the map and its word (QUIZ-R05, R16), drawn by the shared `PalateReadingLine`.
struct ReadingLine: View {
    var row: MapReadingRow

    var body: some View {
        PalateReadingLine(name: row.name, level: row.level, word: row.word, isStrong: row.isStrong)
    }
}
