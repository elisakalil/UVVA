import Foundation

extension Array {
    /// Slices of at most `size` elements, for CloudKit calls that take a limited number of ids.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
