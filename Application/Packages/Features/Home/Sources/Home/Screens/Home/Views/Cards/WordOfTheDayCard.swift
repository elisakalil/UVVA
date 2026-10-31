import Core
import DesignSystem
import SwiftUI

struct WordOfTheDayCard: View {
    var term: GlossaryTerm

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Word of the day")
            FrostedCard(padding: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(term.term).font(UVVAFont.whiteGrape(24))
                    Text(term.pronunciation)
                        .font(UVVAFont.sans(11)).italic()
                        .foregroundStyle(UVVAColor.cream60)
                        .padding(.top, 4)
                    Text(term.definition)
                        .font(UVVAFont.sans(12, .regular))
                        .lineSpacing(5)
                        .foregroundStyle(UVVAColor.cream84)
                        .padding(.top, 12)
                }
            }
        }
    }
}
