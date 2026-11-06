import Core
import DesignSystem
import SwiftUI

/// Real unfinished lessons, selected once per calendar day by HomeCardsBuilder.
struct LearnShortcutsCard: View {
    @State private var shortcutStackHeight: CGFloat = 0
    @ScaledMetric(relativeTo: .body) private var smallCardHeight: CGFloat = 170
    var resources = HomeResourcesUIModel()
    var suggestions: [HomeLessonSuggestion]
    var onOpen: (HomeLessonSuggestion) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: resources.learnShortcutsCardSectionTitle)
            HStack(alignment: .top, spacing: 14) {
                if let region = suggestions.first(where: { $0.course.kind == .region }) {
                    Button { onOpen(region) } label: {
                        FrostedCard(padding: 18) {
                            VStack(alignment: .leading, spacing: 0) {
                                Eyebrow(text: resources.learnShortcutsCardRegionEyebrow)
                                Text(region.course.title)
                                    .font(UVVAFont.whiteGrape(23))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.4)
                                    .padding(.top, 10)
                                RegionMapPreview(country: region.course.countries.first ?? "", courseID: region.course.id)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.vertical, 18)
                                Spacer(minLength: 16)
                                ActionLabel(text: resources.learnShortcutsCardStartTitle)
                            }
                            .frame(height: max(2 * smallCardHeight + 14, shortcutStackHeight) - 36, alignment: .topLeading)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                let others = suggestions.filter { $0.course.kind != .region }
                if !others.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(others, id: \.lesson.id) { suggestion in
                            Button { onOpen(suggestion) } label: {
                                ShortcutCard(
                                    eyebrow: suggestion.course.kind == .grape
                                        ? resources.learnShortcutsCardGrapeEyebrow : resources.learnShortcutsCardLessonEyebrow,
                                    title: suggestion.course.kind == .grape ? suggestion.course.title : suggestion.lesson.title,
                                    subtitle: suggestion.course.kind == .grape ? suggestion.lesson.title : suggestion.lesson.subtitle,
                                    action: resources.learnShortcutsCardStartTitle,
                                    height: smallCardHeight
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shortcutStackHeight = $0 }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
