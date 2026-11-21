import DesignSystem
import SwiftUI

/// FRI-R15a: the table, for two or for a group, in a sheet over the hills that opens at 70% of the screen: the menu
/// card, "Share this table" right under it, and how to make each dish.
struct TableSheet: View {
    /// "You & Marina", "The 4 of you".
    var guests: String
    /// "Read from both palate maps · UVVA", "Read from all 4 palate maps · UVVA".
    var footer: String
    /// Nil while the bottles are worked out.
    var bottles: [TableBottleUIModel]?
    var recipes: [TableRecipeUIModel]?
    var canShare: Bool
    var table: TableResourcesUIModel
    var dinner: DinnerResourcesUIModel
    var onShare: (ShareFormat) -> Void

    @State private var detent = Self.openDetent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TableMenuSection(resources: table, intro: nil, guests: guests, footer: footer, bottles: bottles,
                                 canShare: canShare, onShare: onShare, brushTitle: true, showsShares: false)
                // FRI-R21: the share screen opens on the invite, and offers the Story and Save image too.
                ActionButton(table.shareTitleText, isEnabled: canShare) { onShare(.whatsApp) }
                    .padding(.top, 16)
                if let recipes, !recipes.isEmpty {
                    FriendsCardTitle(text: dinner.howToMakeText)
                        .padding(.top, Self.sectionGap)
                        .transition(.opacity)
                    VStack(spacing: 0) {
                        ForEach(recipes) { recipe in
                            if recipe.id != recipes.first?.id { FriendsHairline() }
                            TableRecipeCard(recipe: recipe, resources: dinner)
                                .padding(.vertical, 22)
                        }
                    }
                    .padding(.top, 2)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 40)
            .padding(.bottom, 40)
            .animation(.easeOut(duration: 0.3), value: recipes)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeFade(12, throughBottomInset: true)
        .foregroundStyle(UVVAColor.creamFill)
        // The glass shows the hills it scrolls over, as on the screen under it.
        .environment(\.glassPhoto, .hills)
        .presentationDetents([Self.openDetent, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground { PageBackground(photo: UVVAPhoto.hills, veiled: true) }
    }

    private static let sectionGap: CGFloat = 52
    private static let openDetent = PresentationDetent.fraction(0.7)
}

/// A course of the table and how to make its dish (FRI-R15a): the course and its bottle, the dish, why it works,
/// what you need and the method. No card: the courses are parted by a hairline.
struct TableRecipeCard: View {
    var recipe: TableRecipeUIModel
    var resources: DinnerResourcesUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(recipe.courseText) · \(recipe.wineText)".uppercased())
                .font(UVVAFont.sans(8.5))
                .tracking(1.8)
                .opacity(0.6)
                .fixedSize(horizontal: false, vertical: true)
            Text(recipe.title)
                .font(UVVAFont.sans(17))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
            Text(recipe.why)
                .font(UVVAFont.sans(12.5))
                .lineSpacing(4)
                .opacity(0.72)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            if !recipe.servesText.isEmpty {
                Text(recipe.servesText)
                    .font(UVVAFont.sans(11))
                    .opacity(0.6)
                    .padding(.top, 10)
            }
            if !recipe.ingredients.isEmpty {
                label(resources.ingredientsText).padding(.top, 20)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(verbatim: "·")
                                .font(UVVAFont.sans(12.5))
                                .opacity(0.6)
                            Text(item)
                                .font(UVVAFont.sans(12.5, .light))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, 12)
            }
            if !recipe.steps.isEmpty {
                label(resources.methodText).padding(.top, 20)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 11) {
                            Text(String(index + 1))
                                .font(UVVAFont.sans(11, .light))
                                .opacity(0.7)
                                .frame(width: 15, alignment: .leading)
                            Text(step)
                                .font(UVVAFont.sans(12.5, .light))
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .medium))
            .tracking(2)
            .opacity(0.55)
            .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview {
    let model = MockFriendProfileViewModel(isTableOpen: true).uiModel
    Color.clear.sheet(isPresented: .constant(true)) {
        TableSheet(guests: model.guestsText, footer: model.resources.menuFooterText, bottles: model.bottles,
                   recipes: model.recipes, canShare: model.share != nil, table: model.resources.table,
                   dinner: model.resources.dinner, onShare: { _ in })
    }
}
#endif
