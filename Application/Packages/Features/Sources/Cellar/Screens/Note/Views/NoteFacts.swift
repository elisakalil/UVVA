import CoreUI
import DesignSystem
import SwiftUI

/// Grape, Region, Vintage, Type, Alcohol and Producer, three to a row (CELLAR-R26).
struct NoteFacts: View {
    var facts: [NoteFactUIModel]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .topLeading), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
            ForEach(facts) { fact in
                VStack(alignment: .leading, spacing: 7) {
                    NoteEyebrow(text: fact.label)
                    Text(fact.value)
                        .font(UVVAFont.sans(13))
                        .foregroundStyle(NotePalette.ink)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
