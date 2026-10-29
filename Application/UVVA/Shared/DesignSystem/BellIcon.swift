//
//  BellIcon.swift
//  UVVA
//
//  Created by Elisa Elias on 28/10/2026.
//

import SwiftUI

struct BellIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 18
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        path.move(to: p(4.6, 7.4))
        path.addArc(center: p(9, 7.4), radius: 4.4 * s, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        path.addLine(to: p(13.4, 10.5))
        path.addLine(to: p(14.7, 12.6))
        path.addLine(to: p(3.3, 12.6))
        path.addLine(to: p(4.6, 10.5))
        path.closeSubpath()
        path.move(to: p(7.3, 14.3))
        path.addArc(center: p(9, 14.3), radius: 1.7 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        return path
    }
}
