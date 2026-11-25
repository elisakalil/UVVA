#if os(iOS)
import DesignSystem
import SwiftUI

/// "What's on the table?" (WINELIST-R06): the dish, the budget from the list's own prices, and who is drinking.
/// Everything can be skipped: with nothing chosen, the wines are ranked by the palate alone.
struct WineListQuestionsView: View {
    var model: WineListUIModel
    var onBack: () -> Void
    var onDish: (String) -> Void
    var onBudget: (String) -> Void
    var onPerson: (String) -> Void
    var onOrder: () -> Void

    private var resources: WineListResourcesUIModel { model.resources }

    var body: some View {
        ZStack {
            PageBackground(veiled: true)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    WineListTopBar(caption: model.wineCountText, backText: resources.backText, onBack: onBack)
                    Text(resources.questionsTitleText)
                        .font(UVVAFont.whiteGrape(34))
                        .padding(.top, 32)
                        .accessibilityAddTraits(.isHeader)
                    Text(resources.questionsBodyText)
                        .font(UVVAFont.sans(13))
                        .foregroundStyle(UVVAColor.cream84)
                        .padding(.top, 10)
                    group(resources.dishLabelText, chips: model.dishes, onTap: onDish)
                    if !model.budgets.isEmpty {
                        group(resources.budgetLabelText, chips: model.budgets, onTap: onBudget)
                    }
                    if !model.people.isEmpty {
                        group(resources.peopleLabelText, chips: model.people, onTap: onPerson)
                        Text(resources.peopleNoteText)
                            .font(UVVAFont.sans(11))
                            .foregroundStyle(UVVAColor.cream60)
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                ActionButton(resources.orderButtonText, action: onOrder)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
    }

    private func group(_ title: String, chips: [WineListChipUIModel], onTap: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9, .semibold))
                .tracking(3.2)
                .foregroundStyle(UVVAColor.creamFill.opacity(0.82))
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(chips) { chip in
                    Chip(text: chip.text, isSelected: chip.isSelected,
                         action: chip.isFixed ? nil : { withAnimation(.easeOut(duration: 0.18)) { onTap(chip.id) } })
                }
            }
        }
        .padding(.top, 34)
        .sensoryFeedback(.selection, trigger: chips.map(\.isSelected))
    }
}
#endif
