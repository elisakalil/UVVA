import SwiftUI

/// Radar of the eight axes with every axis named: the wine's shape, and the user's map dashed over it when given.
/// Where the two overlap is filled.
public struct WineMapChart: View {
    private let labels: [String]
    private let wine: [Double]
    private let palate: [Double]?
    private let tint: Color

    public init(labels: [String], wine: [Double], palate: [Double]? = nil, tint: Color = UVVAColor.cream) {
        self.labels = labels
        self.wine = wine
        self.palate = palate
        self.tint = tint
    }

    /// Room left around the rings for the axis names.
    private static let labelGap: CGFloat = 16
    private static let labelWidth: CGFloat = 120

    private func point(_ index: Int, _ fraction: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double(index) / Double(labels.count) * 2 * .pi - .pi / 2
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

    public var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) / 2 - Self.labelGap - 6
            let wineValues = wine
            ZStack {
                Canvas { context, _ in
                    let line = GraphicsContext.Shading.color(tint.opacity(0.28))
                    for ring in [1.0 / 3, 2.0 / 3, 1] {
                        let r = radius * ring
                        context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)),
                                       with: line, lineWidth: 0.6)
                    }
                    for index in labels.indices {
                        var spoke = Path()
                        spoke.move(to: center)
                        spoke.addLine(to: point(index, 1, center: center, radius: radius))
                        context.stroke(spoke, with: .color(tint.opacity(0.22)), lineWidth: 0.6)
                    }
                    let wineShape = shape(wineValues, center: center, radius: radius)
                    if let palate {
                        let palateValues = palate
                        let overlap = zip(wineValues, palateValues).map { min($0, $1) }
                        context.fill(shape(overlap, center: center, radius: radius), with: .color(tint.opacity(0.22)))
                        context.stroke(shape(palateValues, center: center, radius: radius), with: .color(tint),
                                       style: StrokeStyle(lineWidth: 1.2, lineJoin: .round, dash: [3, 2]))
                    } else {
                        context.fill(wineShape, with: .color(tint.opacity(0.18)))
                    }
                    context.stroke(wineShape, with: .color(tint.opacity(0.9)),
                                   style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                }
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    let tip = point(index, 1, center: center, radius: radius + Self.labelGap)
                    // Names on the right start at the tip, names on the left end at it, top and bottom centre on it.
                    let side = sin(Double(index) / Double(labels.count) * 2 * .pi)
                    let alignment: Alignment = abs(side) < 0.1 ? .center : side > 0 ? .leading : .trailing
                    let shift: CGFloat = abs(side) < 0.1 ? 0 : side > 0 ? Self.labelWidth / 2 : -Self.labelWidth / 2
                    Text(label.uppercased())
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
