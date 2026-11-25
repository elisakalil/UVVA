import Foundation

/// "A bottle, up to" (WINELIST-R06): two limits from the list's own prices, at a third and two thirds of the way up,
/// rounded up to a round number, and no limit. A list without two prices asks nothing.
enum WineListBudget {
    static func options(prices: [Double]) -> [Double] {
        let sorted = Set(prices).sorted()
        guard sorted.count >= 2 else { return [] }
        let at: (Double) -> Double = { share in sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * share))] }
        return Array(Set([round(at(1.0 / 3)), round(at(2.0 / 3))])).sorted()
            .filter { $0 < (sorted.last ?? 0) }
    }

    /// Up to the next 5 under 100, 10 under 300, 50 above.
    static func round(_ price: Double) -> Double {
        let step: Double = price < 100 ? 5 : price < 300 ? 10 : 50
        return (price / step).rounded(.up) * step
    }
}
