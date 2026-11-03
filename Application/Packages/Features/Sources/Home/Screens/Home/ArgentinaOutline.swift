import SwiftUI

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
