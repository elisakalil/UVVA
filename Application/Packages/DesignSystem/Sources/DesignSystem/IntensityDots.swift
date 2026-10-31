import SwiftUI

/// Intensity of one axis as six dots: filled up to the value, small rings after it.
public struct IntensityDots: View {
    var value: Double
    var maxValue: Double
    static let count = 6

    /// `value` on a scale of 0...`maxValue` (the palate scale is 0...9).
    public init(value: Double, maxValue: Double = 9) {
        self.value = value
        self.maxValue = maxValue
    }

    private var filled: Int { Int((value / maxValue * Double(Self.count)).rounded()) }

    public var body: some View {
        HStack(spacing: 4.5) {
            ForEach(0..<Self.count, id: \.self) { index in
                if index < filled {
                    Circle().fill(UVVAColor.cream).frame(width: 3.5, height: 3.5)
                } else {
                    Circle().strokeBorder(UVVAColor.cream60, lineWidth: 0.7).frame(width: 3.5, height: 3.5)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(filled) of \(Self.count)")
    }
}
