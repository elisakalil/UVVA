import Core
import DesignSystem
import SwiftUI

/// Two radars side by side, swiped or tapped between: the wine's own map, then the wine over the user's map.
///
/// A paging scroll view rather than a paged `TabView`: the `TabView` hosts each slide in a UIKit page of its own,
/// and inside the Home's scroll those pages were laid out again on every frame, so the scroll dragged
/// whenever the open card was on screen.
struct WineMapPager: View {
    var wine: PalateMap
    var palate: PalateMap
    @State private var shown: Int? = 0

    private var page: Int { shown ?? 0 }

    var body: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    slide(title: "The map of this wine") {
                        WineMapChart(wine: wine, palate: nil)
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(0)
                    slide(title: "This wine and you") {
                        WineMapChart(wine: wine, palate: palate)
                    } legend: {
                        HStack(spacing: 18) {
                            legendItem("This wine", dashed: false)
                            legendItem("Your map", dashed: true)
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(1)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $shown)
            .frame(height: 262)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.smooth) { shown = page == 0 ? 1 : 0 } }

            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? UVVAColor.cream : UVVAColor.cream.opacity(0.35))
                        .frame(width: index == page ? 18 : 4, height: 4)
                }
            }
            .animation(.smooth(duration: 0.25), value: page)
            .accessibilityHidden(true)
        }
    }

    private func slide<Chart: View>(title: String, @ViewBuilder chart: () -> Chart) -> some View {
        slide(title: title, chart: chart) { EmptyView() }
    }

    private func slide<Chart: View, Legend: View>(title: String, @ViewBuilder chart: () -> Chart,
                                                  @ViewBuilder legend: () -> Legend) -> some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(UVVAFont.sans(8.5, .medium))
                .tracking(2.2)
            chart()
                .frame(maxWidth: .infinity)
                .frame(height: 206)
            legend()
            Spacer(minLength: 0)
        }
        .foregroundStyle(UVVAColor.cream)
    }

    private func legendItem(_ label: String, dashed: Bool) -> some View {
        HStack(spacing: 8) {
            Path { $0.move(to: .zero); $0.addLine(to: CGPoint(x: 16, y: 0)) }
                .stroke(UVVAColor.cream, style: StrokeStyle(lineWidth: 1.2, dash: dashed ? [3, 2] : []))
                .frame(width: 16, height: 1)
            Text(label.uppercased())
                .font(UVVAFont.sans(9, .regular))
                .tracking(1.8)
        }
    }
}

/// Radar of the eight axes with every axis named: the wine's shape, and the user's map dashed over it when given.
/// Where the two overlap is filled.
private struct WineMapChart: View {
    var wine: PalateMap
    var palate: PalateMap?

    private static let axes = PalateAxis.allCases
    /// Room left around the rings for the axis names.
    private static let labelGap: CGFloat = 16
    private static let labelWidth: CGFloat = 120

    private func point(_ index: Int, _ fraction: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double(index) / Double(Self.axes.count) * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + cos(angle) * radius * fraction, y: center.y + sin(angle) * radius * fraction)
    }

    private func shape(_ fractions: [Double], center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for (index, value) in fractions.enumerated() {
            let p = point(index, max(0.08, value), center: center, radius: radius)
            index == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) / 2 - Self.labelGap - 6
            let wineValues = wine.chartValues
            ZStack {
                Canvas { context, _ in
                    let line = GraphicsContext.Shading.color(UVVAColor.cream.opacity(0.28))
                    for ring in [1.0 / 3, 2.0 / 3, 1] {
                        let r = radius * ring
                        context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)),
                                       with: line, lineWidth: 0.6)
                    }
                    for index in Self.axes.indices {
                        var spoke = Path()
                        spoke.move(to: center)
                        spoke.addLine(to: point(index, 1, center: center, radius: radius))
                        context.stroke(spoke, with: .color(UVVAColor.cream.opacity(0.22)), lineWidth: 0.6)
                    }
                    let wineShape = shape(wineValues, center: center, radius: radius)
                    if let palate {
                        let palateValues = palate.chartValues
                        let overlap = zip(wineValues, palateValues).map { min($0, $1) }
                        context.fill(shape(overlap, center: center, radius: radius), with: .color(UVVAColor.cream.opacity(0.22)))
                        context.stroke(shape(palateValues, center: center, radius: radius), with: .color(UVVAColor.cream),
                                       style: StrokeStyle(lineWidth: 1.2, lineJoin: .round, dash: [3, 2]))
                    } else {
                        context.fill(wineShape, with: .color(UVVAColor.cream.opacity(0.18)))
                    }
                    context.stroke(wineShape, with: .color(UVVAColor.cream.opacity(0.9)),
                                   style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                }
                ForEach(Array(Self.axes.enumerated()), id: \.offset) { index, axis in
                    let tip = point(index, 1, center: center, radius: radius + Self.labelGap)
                    // Names on the right start at the tip, names on the left end at it, top and bottom centre on it.
                    let side = sin(Double(index) / Double(Self.axes.count) * 2 * .pi)
                    let alignment: Alignment = abs(side) < 0.1 ? .center : side > 0 ? .leading : .trailing
                    let shift: CGFloat = abs(side) < 0.1 ? 0 : side > 0 ? Self.labelWidth / 2 : -Self.labelWidth / 2
                    Text(axis.label.uppercased())
                        .font(UVVAFont.sans(8, .medium))
                        .tracking(1.6)
                        .fixedSize()
                        .frame(width: Self.labelWidth, alignment: alignment)
                        .position(x: tip.x + shift, y: tip.y)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
