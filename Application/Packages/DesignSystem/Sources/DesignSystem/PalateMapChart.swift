import SwiftUI

/// The palate map drawn large (Quiz result, share card, You): four rings, four spokes, a dashed shape,
/// a dot per axis that grows with its value, and the axis names around it. 330 × 300 pt.
public struct PalateMapChart: View {
    /// One value per axis in chart order (QUIZ-R01), each 0...1.
    var values: [Double]
    var labels: [String]
    /// Indices of the axes drawn stronger (the top two have a halo).
    var strong: Set<Int>
    var labelSize: CGFloat
    var labelOpacity: Double
    /// An earlier map, drawn faintly under this one (YOU-R10).
    var comparison: [Double]?
    /// A second shape in a fine dotted line, with no fill or dots: the boldest reading of a table (FRI-R19).
    var outline: [Double]?
    var ink: Color

    public init(values: [Double], labels: [String], strong: Set<Int> = [], labelSize: CGFloat = 8,
                labelOpacity: Double = 0.7, comparison: [Double]? = nil, outline: [Double]? = nil,
                ink: Color = UVVAColor.creamFill) {
        self.ink = ink
        self.outline = outline
        self.comparison = comparison
        self.values = values
        self.labels = labels
        self.strong = strong
        self.labelSize = labelSize
        self.labelOpacity = labelOpacity
    }

    public static let size = CGSize(width: 330, height: 300)
    static let box: CGFloat = 264
    static let boxOrigin = CGPoint(x: 33, y: 18)
    static let innerRadius: CGFloat = 16
    static let outerRadius: CGFloat = 96
    static let labelRadius: CGFloat = 122

    static func angle(_ index: Int, of count: Int) -> Double {
        Double(index) / Double(max(count, 1)) * 2 * .pi
    }

    /// The point for a value on an axis, in the 264 pt box.
    static func point(_ value: Double, angle: Double) -> CGPoint {
        let r = innerRadius + CGFloat(min(max(value, 0), 1)) * (outerRadius - innerRadius)
        return CGPoint(x: box / 2 + r * sin(angle), y: box / 2 - r * cos(angle))
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in draw(in: &context) }
                .frame(width: Self.box, height: Self.box)
                .offset(x: Self.boxOrigin.x, y: Self.boxOrigin.y)
            ForEach(labels.indices, id: \.self) { index in label(index) }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        let c = Self.box / 2
        for r in [24.0, 48, 72, 96] {
            context.stroke(Path(ellipseIn: CGRect(x: c - r, y: c - r, width: 2 * r, height: 2 * r)),
                           with: .color(ink.opacity(0.16)), lineWidth: 0.5)
        }
        for degrees in [0.0, 45, 90, 135] {
            let t = degrees * .pi / 180
            var spoke = Path()
            spoke.move(to: CGPoint(x: c - Self.outerRadius * sin(t), y: c + Self.outerRadius * cos(t)))
            spoke.addLine(to: CGPoint(x: c + Self.outerRadius * sin(t), y: c - Self.outerRadius * cos(t)))
            context.stroke(spoke, with: .color(ink.opacity(0.13)), lineWidth: 1)
        }
        if let comparison {
            var earlier = Path()
            earlier.addLines(comparison.indices.map { Self.point(comparison[$0], angle: Self.angle($0, of: comparison.count)) })
            earlier.closeSubpath()
            context.fill(earlier, with: .color(ink.opacity(0.05)))
            context.stroke(earlier, with: .color(ink.opacity(0.35)), style: StrokeStyle(lineWidth: 0.8))
        }
        if let outline {
            var boldest = Path()
            boldest.addLines(outline.indices.map { Self.point(outline[$0], angle: Self.angle($0, of: outline.count)) })
            boldest.closeSubpath()
            context.stroke(boldest, with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: 0.8, dash: [1, 3]))
        }
        let points = values.indices.map { Self.point(values[$0], angle: Self.angle($0, of: values.count)) }
        var shape = Path()
        shape.addLines(points)
        shape.closeSubpath()
        context.fill(shape, with: .color(ink.opacity(0.1)))
        context.stroke(shape, with: .color(ink.opacity(0.6)), style: StrokeStyle(lineWidth: 0.9, dash: [2.5, 3.5]))
        for (index, p) in points.enumerated() {
            let onFive = values[index] * 5
            let size = 6 + onFive * 1.8
            if strong.contains(index) {
                let halo = size + 10
                context.fill(Path(ellipseIn: CGRect(x: p.x - halo / 2, y: p.y - halo / 2, width: halo, height: halo)),
                             with: .color(Color.gray.opacity(0.1)))
            }
            context.fill(Path(ellipseIn: CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size)),
                         with: .color(ink.opacity(0.3 + onFive * 0.14)))
        }
    }

    /// Names sit outside the outer ring: centred at the top and bottom, leaning away from the chart on the sides.
    private func label(_ index: Int) -> some View {
        let t = Self.angle(index, of: labels.count)
        let x = Self.boxOrigin.x + Self.box / 2 + Self.labelRadius * sin(t)
        let y = Self.boxOrigin.y + Self.box / 2 - Self.labelRadius * cos(t)
        let side = sin(t)
        let width: CGFloat = 110
        let alignment: Alignment = side > 0.3 ? .leading : side < -0.3 ? .trailing : .center
        let centerX = side > 0.3 ? x - 4 + width / 2 : side < -0.3 ? x + 4 - width / 2 : x
        return Text(labels[index].uppercased())
            .font(UVVAFont.sans(labelSize, .regular))
            .tracking(labelSize * 0.24)
            .lineLimit(1)
            .fixedSize()
            .frame(width: width, alignment: alignment)
            .foregroundStyle(ink)
            .opacity(labelOpacity)
            .position(x: centerX, y: y)
    }
}
