import Core
import DesignSystem
import SwiftUI

/// The recipe under the day's pairing: ingredients, steps, how to serve (HOME-R09).
struct RecipeDetails: View {
    var dish: Dish
    var serving: ClosedRange<Int>?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let serves = dish.serves {
                Text(serves).font(UVVAFont.sans(11)).foregroundStyle(UVVAColor.cream60)
            }
            if !dish.ingredients.isEmpty {
                Caption(text: "Ingredients").padding(.top, 14)
                ForEach(dish.ingredients, id: \.self) { line in
                    Text(line).font(UVVAFont.sans(12, .regular)).foregroundStyle(UVVAColor.cream84)
                }
            }
            if !dish.steps.isEmpty {
                Caption(text: "Steps").padding(.top, 14)
                ForEach(Array(dish.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)").font(UVVAFont.sans(12, .ultraLight))
                        Text(step).font(UVVAFont.sans(12, .regular)).lineSpacing(4).foregroundStyle(UVVAColor.cream84)
                    }
                }
            }
            if let serving {
                Caption(text: "To serve").padding(.top, 14)
                Text("Serve the wine at \(serving.lowerBound)–\(serving.upperBound) °C.")
                    .font(UVVAFont.sans(12, .regular)).foregroundStyle(UVVAColor.cream84)
            }
        }
    }
}
