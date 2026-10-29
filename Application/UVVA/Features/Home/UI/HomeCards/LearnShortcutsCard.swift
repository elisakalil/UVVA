//
//  LearnShortcutsCard.swift
//  UVVA
//
//  Created by Elisa Elias on 28/10/2026.
//

import SwiftUI

/// Learn section: a tall region card with its map on the left, a grape and a lesson stacked on the right.
struct LearnShortcutsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Learn")
            HStack(alignment: .top, spacing: 14) {
                FrostedCard(padding: 18) {
                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow(text: "A region")
                        Text("Uco Valley").font(UVVAFont.whiteGrape(23)).padding(.top, 10)
                        Text("Malbec at altitude").font(UVVAFont.sans(12, .regular)).foregroundStyle(UVVAColor.cream84)
                            .padding(.top, 6)
                        ArgentinaOutline()
                            .stroke(UVVAColor.cream.opacity(0.55), style: StrokeStyle(lineWidth: 0.8, lineJoin: .round))
                            .aspectRatio(0.46, contentMode: .fit)
                            .frame(maxHeight: 130)
                            .overlay(alignment: .topLeading) {
                                GeometryReader { proxy in
                                    RegionPin().position(x: proxy.size.width * 0.17, y: proxy.size.height * 0.34)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        Spacer(minLength: 0)
                        Eyebrow(text: "6 lessons")
                    }
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }

                VStack(spacing: 14) {
                    ShortcutCard(eyebrow: "A grape", title: "Tempranillo", subtitle: "Spain's great red", action: "6 lessons")
                    ShortcutCard(eyebrow: "A lesson", title: "Organic, biodynamic and natural",
                                 subtitle: "What the labels really mean", action: "Start")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ShortcutCard: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var action: String

    var body: some View {
        FrostedCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: eyebrow)
                Text(title).font(UVVAFont.sans(17.5)).padding(.top, 12)
                Text(subtitle).font(UVVAFont.sans(12, .regular)).foregroundStyle(UVVAColor.cream84).padding(.top, 8)
                ActionLabel(text: action).padding(.top, 18)
            }
        }
    }
}

private struct RegionPin: View {
    var body: some View {
        Circle().fill(UVVAColor.cream).frame(width: 6, height: 6)
            .background(Circle().strokeBorder(UVVAColor.cream.opacity(0.6), lineWidth: 0.6).frame(width: 15, height: 15))
    }
}

/// A loose outline of Argentina, drawn in a 0...1 box.
struct ArgentinaOutline: Shape {
    private static let points: [(CGFloat, CGFloat)] = [
        (0.30, 0.00), (0.52, 0.02), (0.60, 0.08), (0.78, 0.10), (0.96, 0.13), (0.90, 0.19), (0.72, 0.24),
        (0.67, 0.30), (0.74, 0.36), (0.63, 0.39), (0.71, 0.45), (0.56, 0.50), (0.48, 0.52), (0.54, 0.56),
        (0.43, 0.59), (0.45, 0.65), (0.36, 0.69), (0.39, 0.75), (0.31, 0.81), (0.33, 0.87), (0.26, 0.91),
        (0.36, 0.97), (0.22, 1.00), (0.19, 0.93), (0.13, 0.85), (0.10, 0.72), (0.14, 0.59), (0.11, 0.46),
        (0.15, 0.31), (0.20, 0.16), (0.25, 0.06)
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (i, (x, y)) in Self.points.enumerated() {
            let p = CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }
}
