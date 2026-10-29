//
//  DailySuggestionCard.swift
//  UVVA
//
//  Created by Elisa Elias on 28/10/2026.
//

import SwiftUI

struct DailySuggestionCard: View {
    var wine: Wine
    var palateMap: PalateMap
    @State private var open = false

    /// The user's three strongest axes, read on this wine.
    private var axes: [Axis] { Array(palateMap.ranked.prefix(3)) }

    /// Why it was picked: the user's top axes on which this wine is also high.
    private var reason: String? {
        let shared = axes.filter { wine.profile[$0] >= 5 }.prefix(2).map(\.rawValue)
        switch shared.count {
        case 2: return "Your map likes \(shared[0]) and \(shared[1]), and this wine is high on both."
        case 1: return "Your map likes \(shared[0]), and this wine is high on it."
        default: return nil
        }
    }

    var body: some View {
        FrostedCard(radius: UVVARadius.hero, padding: 26) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Picked for your palate")
                    .font(UVVAFont.sans(13, .regular))
                    .foregroundStyle(UVVAColor.cream84)

                Text(wine.name)
                    .font(UVVAFont.sans(32))
                    .lineSpacing(-2)
                    .padding(.top, 18)
                Caption(text: wine.origin)
                    .padding(.top, 12)

                Text([reason, wine.note].compactMap { $0 }.joined(separator: " "))
                    .font(UVVAFont.sans(12, .regular))
                    .lineSpacing(6)
                    .foregroundStyle(UVVAColor.cream84)
                    .padding(.top, 30)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(axes, id: \.self) { axis in
                        VStack(alignment: .leading, spacing: 9) {
                            Text(axis.label.uppercased())
                                .font(UVVAFont.sans(8, .medium))
                                .tracking(2.2)
                                .foregroundStyle(UVVAColor.cream84)
                            IntensityDots(value: wine.profile[axis])
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 26)

                if let dish = wine.dish, open {
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle().fill(UVVAColor.cream14).frame(height: 0.5).padding(.bottom, 10)
                        Caption(text: "The perfect table")
                        Text(dish.title).font(UVVAFont.sans(16))
                        Text(dish.why).font(UVVAFont.sans(12, .regular)).lineSpacing(5).foregroundStyle(UVVAColor.cream84)
                    }
                    .padding(.top, 26)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(spacing: 6) {
                    PillButton(style: .outline, action: {}) { Text("Find the wine") }
                    PillButton(action: { withAnimation(.smooth) { open.toggle() } }) {
                        HStack(spacing: 10) {
                            Text(open ? "Show less" : "See the wine & the dish")
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .regular))
                                .rotationEffect(.degrees(open ? 180 : 0))
                        }
                    }
                }
                .padding(.top, 26)
            }
        }
    }
}
