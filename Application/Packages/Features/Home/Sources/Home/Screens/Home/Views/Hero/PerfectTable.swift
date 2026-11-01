import Core
import DesignSystem
import SwiftUI

/// The dish under the day's wine, beside its engraved plate: why it works, what you need, how to make it
/// and how to serve (HOME-R09).
struct PerfectTable: View {
    var dish: Dish
    var serving: ClosedRange<Int>?

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            UVVAIllustration.plate
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 24)
                .foregroundStyle(UVVAColor.creamFill)
                .padding(.top, 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                label("The perfect table", tracking: 1.6)
                Text(dish.title)
                    .font(UVVAFont.sans(14, .medium))
                    .lineSpacing(3)
                    .padding(.top, 9)
                Text(dish.why)
                    .font(UVVAFont.sans(12.5, .regular))
                    .lineSpacing(5)
                    .padding(.top, 8)
                if let serves = dish.serves {
                    Text(serves)
                        .font(UVVAFont.sans(11, .regular))
                        .foregroundStyle(UVVAColor.cream60)
                        .padding(.top, 10)
                }

                if !dish.ingredients.isEmpty {
                    label("What you need", tracking: 2).padding(.top, 18)
                    FlowLayout(spacing: 7, lineSpacing: 7) {
                        ForEach(dish.ingredients, id: \.self) { item in
                            Text(item)
                                .font(UVVAFont.sans(11, .light))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .overlay(Capsule().strokeBorder(UVVAColor.cream.opacity(0.28), lineWidth: 0.5))
                        }
                    }
                    .padding(.top, 10)
                }

                if !dish.steps.isEmpty {
                    label("How to make it", tracking: 2).padding(.top, 18)
                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(Array(dish.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 11) {
                                Text("\(index + 1)")
                                    .font(UVVAFont.sans(11, .light))
                                    .foregroundStyle(UVVAColor.cream.opacity(0.75))
                                    .frame(width: 15, alignment: .leading)
                                Text(step)
                                    .font(UVVAFont.sans(12, .light))
                                    .lineSpacing(5)
                            }
                        }
                    }
                    .padding(.top, 12)
                }

                if let serving {
                    Text("Serve the wine at \(serving.lowerBound)–\(serving.upperBound) °C.")
                        .font(UVVAFont.sans(12, .light))
                        .lineSpacing(5)
                        .padding(.top, 16)
                }
            }
            .foregroundStyle(UVVAColor.cream)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func label(_ text: String, tracking: CGFloat) -> some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .regular))
            .tracking(tracking)
    }
}
