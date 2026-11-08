import Foundation

/// Interpolates between the displayed coordinates and the selected measurement.
struct HistoryMapTransition: Equatable {
    static let duration = 0.65

    var from: [Double]
    var to: [Double]
    var startedAt: Date

    func values(at date: Date) -> [Double] {
        let elapsed = date.timeIntervalSince(startedAt)
        guard elapsed > 0 else { return from }
        guard elapsed < Self.duration else { return to }

        let progress = elapsed / Self.duration
        let eased = progress * progress * (3 - 2 * progress)
        return zip(from, to).map { start, end in start + (end - start) * eased }
    }
}
