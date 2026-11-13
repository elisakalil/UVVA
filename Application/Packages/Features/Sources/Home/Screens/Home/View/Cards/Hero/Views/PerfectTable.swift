import Core
import DesignSystem
import SwiftUI

/// The dish under the day's wine, beside its engraved plate: why it works, what you need and how to make it
/// (HOME-R09). The serving temperature is left to the wine's facts above.
struct PerfectTable: View {
    var resources = HomeResourcesUIModel()
    var dish: Dish

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            resources.plateImage
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 24)
                .foregroundStyle(Color.white)
                .padding(.top, 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                label(resources.perfectTableTitle, tracking: 1.6)
                // Title and why wrap like the steps, onto as many lines as they need instead of ending in "…".
                Text(dish.title)
                    .font(UVVAFont.sans(14, .medium))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)
                Text(dish.why)
                    .font(UVVAFont.sans(12.5, .regular))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                if let serves = dish.serves {
                    Text(serves)
                        .font(UVVAFont.sans(11, .regular))
                        .foregroundStyle(.white)
                        .padding(.top, 10)
                }

                if !dish.ingredients.isEmpty {
                    label(resources.perfectTableIngredientsTitle, tracking: 2).padding(.top, 18)
                    FlowLayout(spacing: 7, lineSpacing: 7) {
                        ForEach(dish.ingredients, id: \.self) { item in
                            Text(item)
                                .font(UVVAFont.sans(11, .light))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.5))
                        }
                    }
                    .padding(.top, 10)
                }

                if !dish.steps.isEmpty {
                    label(resources.perfectTableStepsTitle, tracking: 2).padding(.top, 18)
                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(Array(dish.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 11) {
                                Text(String(index + 1))
                                    .font(UVVAFont.sans(11, .light))
                                    .foregroundStyle(.white)
                                    .frame(width: 15, alignment: .leading)
                                // Wraps onto as many lines as the step needs instead of ending in "…".
                                Text(step)
                                    .font(UVVAFont.sans(12, .light))
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func label(_ text: String, tracking: CGFloat) -> some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .regular))
            .tracking(tracking)
    }
}
