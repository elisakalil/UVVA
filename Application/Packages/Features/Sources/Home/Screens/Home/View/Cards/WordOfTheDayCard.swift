import Core
import DesignSystem
import SwiftUI

struct WordOfTheDayCard: View {
    var resources = HomeResourcesUIModel()
    var term: GlossaryTerm

    var body: some View {
        FrostedCard(padding: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: resources.wordOfTheDayCardSectionTitle)
                Text(term.term).font(UVVAFont.whiteGrape(24))
            }
        }
    }
}
