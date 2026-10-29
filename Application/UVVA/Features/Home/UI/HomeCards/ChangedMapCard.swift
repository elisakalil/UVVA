//
//  ChangedMapCard.swift
//  UVVA
//
//  Created by Elisa Elias on 28/10/2026.
//

import SwiftUI

/// Half-width card: the palate map with the axis that moved, and one line on what changed.
struct ChangedMapCard: View {
    var axis: Axis
    var delta: Double
    var palateMap: PalateMap

    var body: some View {
        FrostedCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                PalateRadar(map: palateMap, highlight: axis)
                    .frame(width: 70, height: 70)
                    .padding(.top, 14)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 16)
                Text("Your last wine \(delta >= 0 ? "raised" : "lowered") your \(axis.rawValue) notes.")
                    .font(UVVAFont.sans(12, .regular))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// Small radar of the eight axes: three rings, spokes, the map's shape and the highlighted axis named at its tip.
/// The highlighted axis is turned to the top.
struct PalateRadar: View {
    var map: PalateMap
    var highlight: Axis?

    private func point(_ axis: Axis, _ fraction: Double, in rect: CGRect) -> CGPoint {
        let first = Axis.allCases.firstIndex(of: highlight ?? Axis.allCases[0]) ?? 0
        let index = Double((Axis.allCases.firstIndex(of: axis) ?? 0) - first)
        let angle = index / Double(Axis.allCases.count) * 2 * .pi - .pi / 2
        let radius = min(rect.width, rect.height) / 2 * fraction
        return CGPoint(x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius)
    }

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let line = GraphicsContext.Shading.color(UVVAColor.cream.opacity(0.28))
            for ring in [1.0 / 3, 2.0 / 3, 1] {
                let r = min(size.width, size.height) / 2 * ring
                context.stroke(Path(ellipseIn: CGRect(x: rect.midX - r, y: rect.midY - r, width: 2 * r, height: 2 * r)),
                               with: line, lineWidth: 0.5)
            }
            for axis in Axis.allCases {
                var spoke = Path()
                spoke.move(to: CGPoint(x: rect.midX, y: rect.midY))
                spoke.addLine(to: point(axis, axis == highlight ? 1.25 : 1, in: rect))
                context.stroke(spoke, with: axis == highlight ? .color(UVVAColor.cream.opacity(0.8)) : line,
                               lineWidth: axis == highlight ? 0.8 : 0.5)
            }
            var shape = Path()
            for (i, axis) in Axis.allCases.enumerated() {
                let p = point(axis, map[axis] / PalateMap.range.upperBound, in: rect)
                i == 0 ? shape.move(to: p) : shape.addLine(to: p)
            }
            shape.closeSubpath()
            context.fill(shape, with: .color(UVVAColor.cream.opacity(0.18)))
            context.stroke(shape, with: .color(UVVAColor.cream.opacity(0.85)), style: StrokeStyle(lineWidth: 1, lineJoin: .round))
            if let highlight {
                let p = point(highlight, map[highlight] / PalateMap.range.upperBound, in: rect)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(UVVAColor.cream))
            }
        }
        .overlay {
            if let highlight {
                GeometryReader { proxy in
                    let tip = point(highlight, 1.25, in: CGRect(origin: .zero, size: proxy.size))
                    Text(highlight.label.uppercased())
                        .font(UVVAFont.sans(7.5, .medium))
                        .tracking(1.8)
                        .fixedSize()
                        .position(x: tip.x + 28, y: tip.y + 2)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
