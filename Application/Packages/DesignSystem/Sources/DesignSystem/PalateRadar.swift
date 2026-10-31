import SwiftUI

/// Small radar of the eight axes: three rings, spokes, the map's shape and the highlighted axis named at its tip.
/// The highlighted axis is turned to the top.
public struct PalateRadar: View {
    /// One value per axis in chart order (QUIZ-R01), each 0...1.
    var values: [Double]
    /// Index into `values` of the axis to highlight.
    var highlight: Int?
    var highlightLabel: String?

    public init(values: [Double], highlight: Int? = nil, highlightLabel: String? = nil) {
        self.values = values
        self.highlight = highlight
        self.highlightLabel = highlightLabel
    }

    private func point(_ index: Int, _ fraction: Double, in rect: CGRect) -> CGPoint {
        let turned = Double(index - (highlight ?? 0))
        let angle = turned / Double(values.count) * 2 * .pi - .pi / 2
        let radius = min(rect.width, rect.height) / 2 * fraction
        return CGPoint(x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius)
    }

    public var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let line = GraphicsContext.Shading.color(UVVAColor.cream.opacity(0.28))
            for ring in [1.0 / 3, 2.0 / 3, 1] {
                let r = min(size.width, size.height) / 2 * ring
                context.stroke(Path(ellipseIn: CGRect(x: rect.midX - r, y: rect.midY - r, width: 2 * r, height: 2 * r)),
                               with: line, lineWidth: 0.5)
            }
            for index in values.indices {
                var spoke = Path()
                spoke.move(to: CGPoint(x: rect.midX, y: rect.midY))
                spoke.addLine(to: point(index, index == highlight ? 1.25 : 1, in: rect))
                context.stroke(spoke, with: index == highlight ? .color(UVVAColor.cream.opacity(0.8)) : line,
                               lineWidth: index == highlight ? 0.8 : 0.5)
            }
            var shape = Path()
            for (index, value) in values.enumerated() {
                let p = point(index, value, in: rect)
                index == 0 ? shape.move(to: p) : shape.addLine(to: p)
            }
            shape.closeSubpath()
            context.fill(shape, with: .color(UVVAColor.cream.opacity(0.18)))
            context.stroke(shape, with: .color(UVVAColor.cream.opacity(0.85)), style: StrokeStyle(lineWidth: 1, lineJoin: .round))
            if let highlight, values.indices.contains(highlight) {
                let p = point(highlight, values[highlight], in: rect)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(UVVAColor.cream))
            }
        }
        .overlay {
            if let highlight, let highlightLabel {
                GeometryReader { proxy in
                    let tip = point(highlight, 1.25, in: CGRect(origin: .zero, size: proxy.size))
                    Text(highlightLabel.uppercased())
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
