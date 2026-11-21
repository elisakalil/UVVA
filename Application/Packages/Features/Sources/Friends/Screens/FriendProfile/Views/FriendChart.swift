import Core
import DesignSystem
import SwiftUI

/// The friend's map inside the "[Name] Map" card (FRI-R11): four rings, four spokes, the shape filled and drawn in a
/// solid line, a dot per axis that grows with its value, and the axis names close around it.
/// 294 × 264 pt, half as large again as the design's 196 × 176, filling the card; the two strongest dots breathe.
struct FriendMiniChart: View {
    var values: [Double]
    var strong: Set<Int>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBright = false

    /// The design's chart, scaled up to fill the card.
    private static let scale: CGFloat = 1.5
    private static let size = CGSize(width: 196 * scale, height: 176 * scale)
    private static let center = CGPoint(x: 98 * scale, y: 88 * scale)
    private static let innerRadius: CGFloat = 7 * scale
    private static let outerRadius: CGFloat = 44 * scale
    private static let labelRadius: CGFloat = 68 * scale

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in draw(in: &context) }
            ForEach(values.indices, id: \.self) { dot($0) }
            ForEach(PalateAxisLabels.all.indices, id: \.self) { label($0) }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { isBright = true }
        }
    }

    private static func point(_ value: Double, index: Int, of count: Int) -> CGPoint {
        let r = innerRadius + CGFloat(min(max(value, 0), 1)) * (outerRadius - innerRadius)
        let t = Double(index) / Double(max(count, 1)) * 2 * .pi
        return CGPoint(x: center.x + r * sin(t), y: center.y - r * cos(t))
    }

    private func draw(in context: inout GraphicsContext) {
        let ink = UVVAColor.creamFill
        let c = Self.center
        for r in [11.0, 22, 33, 44].map({ $0 * Self.scale }) {
            context.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                           with: .color(ink.opacity(0.3)), lineWidth: 0.5)
        }
        for degrees in [0.0, 45, 90, 135] {
            let t = degrees * .pi / 180
            var spoke = Path()
            spoke.move(to: CGPoint(x: c.x - Self.outerRadius * cos(t), y: c.y - Self.outerRadius * sin(t)))
            spoke.addLine(to: CGPoint(x: c.x + Self.outerRadius * cos(t), y: c.y + Self.outerRadius * sin(t)))
            context.stroke(spoke, with: .color(ink.opacity(0.26)), lineWidth: 1)
        }
        guard values.count > 2 else { return }
        var shape = Path()
        shape.addLines(values.indices.map { Self.point(values[$0], index: $0, of: values.count) })
        shape.closeSubpath()
        context.fill(shape, with: .color(ink.opacity(0.2)))
        context.stroke(shape, with: .color(ink.opacity(0.9)), style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
    }

    /// The dot grows and brightens with the value (0...5 on the chart's own scale).
    private func dot(_ index: Int) -> some View {
        let onFive = min(max(values[index], 0), 1) * 5
        let size = (4 + onFive * 0.8) * Self.scale
        let p = Self.point(values[index], index: index, of: values.count)
        let opacity = 0.3 + onFive * 0.14
        let breathes = strong.contains(index) && !reduceMotion
        return Circle()
            .fill(UVVAColor.creamFill)
            .frame(width: size, height: size)
            .opacity(breathes ? opacity * (isBright ? 1 : 0.55) : opacity)
            .position(p)
    }

    private func label(_ index: Int) -> some View {
        let labels = PalateAxisLabels.all
        let t = Double(index) / Double(labels.count) * 2 * .pi
        return Text(labels[index].uppercased())
            .font(UVVAFont.sans(8, .medium))
            .tracking(1.3)
            .lineLimit(1)
            .fixedSize()
            .opacity(0.88)
            .position(x: Self.center.x + Self.labelRadius * sin(t), y: Self.center.y - Self.labelRadius * cos(t))
    }
}

/// Two maps over each other on the large chart frame of `PalateMapChart` (330 × 300 pt, four rings, four spokes,
/// the axis names around it).
/// - `overlap` (FRI-R12): the user's map in a solid line, the friend's dashed, and where they meet filled.
/// - `table` (FRI-R19): where the table lands filled and in a solid line with its dots, the boldest reading dashed.
struct FriendsMapChart: View {
    enum Style {
        case overlap(mine: [Double], theirs: [Double])
        case table(average: [Double], boldest: [Double])
    }

    var style: Style

    private static let size = CGSize(width: 330, height: 300)
    private static let box: CGFloat = 264
    private static let origin = CGPoint(x: 33, y: 18)
    private static let innerRadius: CGFloat = 16
    private static let outerRadius: CGFloat = 96
    private static let labelRadius: CGFloat = 122

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in draw(in: &context) }
                .frame(width: Self.box, height: Self.box)
                .offset(x: Self.origin.x, y: Self.origin.y)
            ForEach(PalateAxisLabels.all.indices, id: \.self) { label($0) }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private static func angle(_ index: Int, of count: Int) -> Double {
        Double(index) / Double(max(count, 1)) * 2 * .pi
    }

    private static func radius(_ value: Double) -> Double {
        innerRadius + min(max(value, 0), 1) * (outerRadius - innerRadius)
    }

    private static func point(_ r: Double, angle: Double) -> CGPoint {
        CGPoint(x: box / 2 + r * sin(angle), y: box / 2 - r * cos(angle))
    }

    private static func shape(_ values: [Double]) -> Path {
        var path = Path()
        path.addLines(values.indices.map { point(radius(values[$0]), angle: angle($0, of: values.count)) })
        path.closeSubpath()
        return path
    }

    /// How far a map's shape reaches in a direction: on the side between the two axes around it.
    private static func reach(_ values: [Double], at theta: Double) -> Double {
        let count = values.count
        guard count > 2 else { return 0 }
        let step = 2 * Double.pi / Double(count)
        let index = min(Int(theta / step), count - 1)
        let (t1, t2) = (Double(index) * step, Double(index + 1) * step)
        let (r1, r2) = (radius(values[index]), radius(values[(index + 1) % count]))
        let denominator = r1 * sin(theta - t1) + r2 * sin(t2 - theta)
        return denominator > 0 ? r1 * r2 * sin(t2 - t1) / denominator : min(r1, r2)
    }

    /// Where two shapes meet, traced every 3°.
    private static func shared(_ mine: [Double], _ theirs: [Double]) -> Path {
        var path = Path()
        let points = stride(from: 0.0, to: 360.0, by: 3).map { degrees -> CGPoint in
            let theta = degrees * .pi / 180
            return point(min(reach(mine, at: theta), reach(theirs, at: theta)), angle: theta)
        }
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    private func draw(in context: inout GraphicsContext) {
        let ink = UVVAColor.creamFill
        let c = Self.box / 2
        for r in [24.0, 48, 72, 96] {
            context.stroke(Path(ellipseIn: CGRect(x: c - r, y: c - r, width: 2 * r, height: 2 * r)),
                           with: .color(ink.opacity(0.3)), lineWidth: 0.5)
        }
        for degrees in [0.0, 45, 90, 135] {
            let t = degrees * .pi / 180
            var spoke = Path()
            spoke.move(to: CGPoint(x: c - Self.outerRadius * sin(t), y: c + Self.outerRadius * cos(t)))
            spoke.addLine(to: CGPoint(x: c + Self.outerRadius * sin(t), y: c - Self.outerRadius * cos(t)))
            context.stroke(spoke, with: .color(ink.opacity(0.26)), lineWidth: 1)
        }
        switch style {
        case let .overlap(mine, theirs):
            guard mine.count == theirs.count, mine.count > 2 else { return }
            context.fill(Self.shared(mine, theirs), with: .color(ink.opacity(0.2)))
            context.stroke(Self.shape(mine), with: .color(ink.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
            context.stroke(Self.shape(theirs), with: .color(ink.opacity(0.75)),
                           style: StrokeStyle(lineWidth: 1, lineJoin: .round, dash: [3, 4]))
        case let .table(average, boldest):
            guard average.count == boldest.count, average.count > 2 else { return }
            let landing = Self.shape(average)
            context.fill(landing, with: .color(ink.opacity(0.07)))
            context.stroke(landing, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: 0.7, lineJoin: .round))
            context.stroke(Self.shape(boldest), with: .color(ink.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 0.7, lineJoin: .round, dash: [3, 4]))
            for index in average.indices {
                let onFive = min(max(average[index], 0), 1) * 5
                let size = 2.6 + onFive * 0.4
                let p = Self.point(Self.radius(average[index]), angle: Self.angle(index, of: average.count))
                context.fill(Path(ellipseIn: CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size)),
                             with: .color(ink.opacity(0.3 + onFive * 0.14)))
            }
        }
    }

    /// Names sit outside the outer ring: centred at the top and bottom, leaning away from the chart on the sides.
    private func label(_ index: Int) -> some View {
        let labels = PalateAxisLabels.all
        let t = Self.angle(index, of: labels.count)
        let x = Self.origin.x + Self.box / 2 + Self.labelRadius * sin(t)
        let y = Self.origin.y + Self.box / 2 - Self.labelRadius * cos(t)
        let side = sin(t)
        let width: CGFloat = 110
        let alignment: Alignment = side > 0.3 ? .leading : side < -0.3 ? .trailing : .center
        let centerX = side > 0.3 ? x - 4 + width / 2 : side < -0.3 ? x + 4 - width / 2 : x
        return Text(labels[index].uppercased())
            .font(UVVAFont.sans(8, .medium))
            .tracking(1.9)
            .lineLimit(1)
            .fixedSize()
            .frame(width: width, alignment: alignment)
            .position(x: centerX, y: y)
    }
}
