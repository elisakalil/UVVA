import Core
import Foundation

/// The texts that read a palate map (QUIZ-R05, R14 to R16, R19). Neutral: no pronoun for the person (QUIZ-R20a).
public struct MapReading: Sendable {
    public let map: PalateMap

    public init(map: PalateMap) { self.map = map }

    /// QUIZ-R14: by value, ties in the canonical order.
    public var ranked: [PalateAxis] { map.ranked }
    public var top3: [PalateAxis] { Array(ranked.prefix(3)) }
    public var weakest: PalateAxis { ranked[ranked.count - 1] }

    /// QUIZ-R15: "Acidity · Fruit · Body".
    public var dominantPhrase: String { top3.map(\.label).joined(separator: " · ") }

    public var caption: String {
        String(localized: "Strongest on \(top3[0].label.lowercased()), quietest on \(weakest.label.lowercased()). The shape of what you reach for in a glass.", bundle: .module)
    }

    /// QUIZ-R15: the high text of the top two and the low text of the weakest.
    public var narrative: String {
        [AxisLore.high(top3[0]), AxisLore.high(top3[1]), AxisLore.low(weakest)]
            .map { $0.prefix(1).uppercased() + $0.dropFirst() + "." }
            .joined(separator: " ")
    }

    /// QUIZ-R19, Loves.
    public func loves(_ firstName: String) -> String {
        String(localized: "\(firstName) drinks for \(top3[0].label.lowercased()), \(top3[1].label.lowercased()) and \(top3[2].label.lowercased()), in that order.", bundle: .module)
    }

    /// Loves, before the person has a name.
    public var lovesWithoutName: String {
        String(localized: "Drinks for \(top3[0].label.lowercased()), \(top3[1].label.lowercased()) and \(top3[2].label.lowercased()), in that order.", bundle: .module)
    }

    /// QUIZ-R19, Never.
    public var never: String {
        String(localized: "Pour something built on \(weakest.label.lowercased()) and the glass comes back. Politely.", bundle: .module)
    }

    /// QUIZ-R05: the displayed level, 0...9.
    public static func level(_ value: Double) -> Int {
        Int(min(max(value.rounded(), 0), 9))
    }

    /// QUIZ-R05
    public static func levelWord(_ level: Int) -> String {
        let words = [
            String(localized: "None", bundle: .module),
            String(localized: "Almost none", bundle: .module),
            String(localized: "A trace", bundle: .module),
            String(localized: "A little", bundle: .module),
            String(localized: "Some", bundle: .module),
            String(localized: "Noticeably", bundle: .module),
            String(localized: "Quite a lot", bundle: .module),
            String(localized: "A lot", bundle: .module),
            String(localized: "Very much", bundle: .module),
            String(localized: "As much as possible", bundle: .module)
        ]
        return words[min(max(level, 0), 9)]
    }
}
