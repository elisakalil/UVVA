//
//  WinesForPalateCard.swift
//  UVVA
//
//  Created by Elisa Elias on 28/10/2026.
//

import SwiftUI

struct WinesForPalateCard: View {
    var wines: [Wine]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Wines for your palate")
            FrostedCard(radius: UVVARadius.hero, padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(wines.enumerated()), id: \.element.id) { index, wine in
                        if index > 0 {
                            Rectangle().fill(UVVAColor.cream14).frame(height: 0.5).padding(.horizontal, 26)
                        }
                        WineRow(wine: wine)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

private struct WineRow: View {
    var wine: Wine

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(wine.name).font(UVVAFont.sans(14.5, .medium))
                if let note = wine.note {
                    Text(note)
                        .font(UVVAFont.sans(12, .regular))
                        .lineSpacing(4)
                        .foregroundStyle(UVVAColor.cream84)
                        .padding(.top, 6)
                }
                if let axis = wine.profile.ranked.first {
                    HStack(spacing: 8) {
                        Text("✷").font(UVVAFont.sans(9))
                        Caption(text: axis.label)
                    }
                    .foregroundStyle(UVVAColor.cream60)
                    .padding(.top, 10)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(UVVAColor.cream60)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}
