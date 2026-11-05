import Core
import Foundation

/// The texts that read a palate map (QUIZ-R05, R14 to R16, R19). Neutral: no pronoun for the person (QUIZ-R20a).
public struct MapReading: Sendable {
    public let map: PalateMap
    /// QUIZ-R14a: the axes grouped by displayed level, highest first. Axes in one tier are tied: no text picks
    /// some of them over the others by the canonical order.
    public let tiers: [[PalateAxis]]

    public init(map: PalateMap) {
        self.map = map
        var tiers: [[PalateAxis]] = []
        for axis in map.ranked {
            if let last = tiers.last?.first, Self.level(map[last]) == Self.level(map[axis]) {
                tiers[tiers.count - 1].append(axis)
            } else {
                tiers.append([axis])
            }
        }
        self.tiers = tiers
    }

    /// QUIZ-R14: by value, ties in the canonical order.
    public var ranked: [PalateAxis] { map.ranked }

    /// QUIZ-R14a
    public var shape: MapShape {
        guard tiers.count > 1 else { return .flat(AxisTone(map[tiers[0][0]])) }
        if tiers.count == 2 {
            if tiers[1].count == 1 { return .allButOneLower(tiers[1][0]) }
            if tiers[0].count == 1 { return .allButOneHigher(tiers[0][0]) }
        }
        return .shaped
    }

    /// QUIZ-R14a: the strongest axes, in whole tiers and at most `limit`. A tie that does not fit is left out
    /// rather than cut, so a flat map has none.
    public func leaders(_ limit: Int) -> [PalateAxis] {
        guard tiers.count > 1 else { return [] }
        var axes: [PalateAxis] = []
        for tier in tiers {
            guard axes.count + tier.count <= limit else { break }
            axes += tier
        }
        return axes
    }

    public var highlighted: [PalateAxis] { leaders(2) }

    public var dominantPhrase: String {
        switch shape {
        case .flat(.low): return String(localized: "Quiet on every axis", bundle: .module)
        case .flat(.neutral): return String(localized: "In the middle on every axis", bundle: .module)
        case .flat(.high): return String(localized: "High on every axis", bundle: .module)
        case let .allButOneLower(axis) where topTone == .high:
            return String(localized: "Everything but \(axis.label.lowercased())", bundle: .module)
        case .allButOneLower, .allButOneHigher, .shaped:
            let top = leaders(3)
            if !top.isEmpty { return top.map(\.label).joined(separator: " · ") }
            // Four to seven axes tied on top. Not high, they are not what the person reaches for.
            if let mostAxes { return mostAxes }
            // High: name the few left out, or else the tie itself.
            let rest = tiers.dropFirst().flatMap { $0 }
            return rest.count <= 2
                ? String(localized: "Everything but \(Self.list(rest))", bundle: .module)
                : tiers[0].map(\.label).joined(separator: " · ")
        }
    }

    /// YOU-R01, FRI-R04: "ACIDITY · FRUIT · BODY".
    public var signature: String { dominantPhrase.uppercased() }

    public var caption: String {
        let head = switch shape {
        case .flat(.low): String(localized: "Quiet on all eight axes.", bundle: .module)
        case .flat(.neutral): String(localized: "In the middle on all eight axes.", bundle: .module)
        case .flat(.high): String(localized: "High on all eight axes.", bundle: .module)
        case let .allButOneLower(axis):
            String(localized: "Even on seven axes, quietest on \(axis.label.lowercased()).", bundle: .module)
        case .allButOneHigher:
            String(localized: "\(topPhrase), even on the other seven.", bundle: .module)
        case .shaped:
            String(localized: "\(topPhrase), quietest on \(Self.group(tiers[tiers.count - 1])).", bundle: .module)
        }
        return head + " " + String(localized: "The shape of what you reach for in a glass.", bundle: .module)
    }

    /// The top's tone (QUIZ-R14a).
    private var topTone: AxisTone { AxisTone(map[tiers[0][0]]) }

    /// The caption's opening (QUIZ-R15): "Strongest on" only for a high top. A low or middle top is only leaned
    /// toward, and a tie of more than three of them is the map at large.
    private var topPhrase: String {
        let top = tiers[0]
        if topTone == .high { return String(localized: "Strongest on \(Self.group(top))", bundle: .module) }
        if let mostAxes { return mostAxes }
        return String(localized: "Leaning most toward \(Self.list(top))", bundle: .module)
    }

    /// Four or more axes tied on a top that is not high: "Quiet on most axes".
    private var mostAxes: String? {
        guard tiers[0].count > 3 else { return nil }
        switch topTone {
        case .low: return String(localized: "Quiet on most axes", bundle: .module)
        case .neutral: return String(localized: "In the middle on most axes", bundle: .module)
        case .high: return nil
        }
    }

    /// QUIZ-R15: what the top says, then what the bottom says. A high text only for a high axis, a low text only
    /// for a low one (QUIZ-R14a).
    public var narrative: String {
        let sentences = if case let .flat(tone) = shape { [AxisLore.flat(tone)] } else { topSentences + bottomSentences }
        return sentences
            .map { $0.prefix(1).uppercased() + $0.dropFirst() + "." }
            .joined(separator: " ")
    }

    private var topSentences: [String] {
        let top = tiers[0]
        guard AxisTone(map[top[0]]) == .high else { return [AxisLore.nothingHigh] }
        guard top.count <= 2 else { return [AxisLore.mostHigh] }
        return leaders(2).filter { AxisTone(map[$0]) == .high }.map(AxisLore.high)
    }

    private var bottomSentences: [String] {
        let bottom = tiers[tiers.count - 1]
        guard AxisTone(map[bottom[0]]) == .low else { return [AxisLore.nothingLow] }
        return bottom.count <= 2 ? bottom.map(AxisLore.low) : [AxisLore.mostLow]
    }

    /// QUIZ-R19, Loves.
    public func loves(_ firstName: String) -> String {
        String(localized: "\(firstName) drinks for \(lovedThings).", bundle: .module)
    }

    /// Loves, before the person has a name.
    public var lovesWithoutName: String {
        String(localized: "Drinks for \(lovedThings).", bundle: .module)
    }

    private var lovedThings: String {
        switch shape {
        case .flat(.low): return String(localized: "restraint, every axis kept low", bundle: .module)
        case .flat(.neutral): return String(localized: "balance, every axis in the middle", bundle: .module)
        case .flat(.high): return String(localized: "everything at once, every axis turned up", bundle: .module)
        case let .allButOneLower(axis) where topTone == .high:
            return String(localized: "everything but \(axis.label.lowercased())", bundle: .module)
        case .allButOneLower, .allButOneHigher, .shaped:
            let top = leaders(3)
            switch top.count {
            case 0 where topTone == .low: return String(localized: "restraint, most axes kept low", bundle: .module)
            case 0 where topTone == .neutral: return String(localized: "balance, most axes in the middle", bundle: .module)
            case 0: return String(localized: "many things at once", bundle: .module)
            case 1: return String(localized: "\(top[0].label.lowercased()) above all", bundle: .module)
            default:
                // "In that order" only when there is one: tied axes have none.
                let levels = top.map { Self.level(map[$0]) }
                return Set(levels).count == levels.count
                    ? String(localized: "\(Self.list(top)), in that order", bundle: .module)
                    : Self.list(top)
            }
        }
    }

    /// QUIZ-R19, Never.
    public var never: String {
        let bottom = tiers[tiers.count - 1]
        if shape == .flat(.low) || (AxisTone(map[bottom[0]]) == .low && bottom.count > 2) {
            return String(localized: "Pour something loud and the glass comes back. Politely.", bundle: .module)
        }
        guard AxisTone(map[bottom[0]]) == .low else {
            return String(localized: "Pour almost anything: nothing on this map sends a glass back.", bundle: .module)
        }
        return String(localized: "Pour something built on \(Self.list(bottom)) and the glass comes back. Politely.", bundle: .module)
    }

    /// "acidity", "acidity and fruit", "floral, body and tannin".
    static func list(_ axes: [PalateAxis]) -> String {
        let names = axes.map { $0.label.lowercased() }
        guard let last = names.last else { return "" }
        guard names.count > 1 else { return last }
        return String(localized: "\(names.dropLast().joined(separator: ", ")) and \(last)", bundle: .module)
    }

    /// A tier in a sentence: its axes, or "several axes at once" past three.
    private static func group(_ tier: [PalateAxis]) -> String {
        tier.count <= 3 ? list(tier) : String(localized: "several axes at once", bundle: .module)
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
