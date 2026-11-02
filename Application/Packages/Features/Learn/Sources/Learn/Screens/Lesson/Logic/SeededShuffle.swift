import Foundation

/// LEARN-R17b: ordering items and the right side of matchPairs, shuffled with a seed fixed per step, so a step
/// looks the same each time it opens; never left in the right order.
enum SeededShuffle {
    /// A permutation of `0..<count`.
    static func order(count: Int, seed: UInt64) -> [Int] {
        var result = Array(0..<count)
        var state = seed
        for index in stride(from: count - 1, to: 0, by: -1) {
            // A 64-bit linear congruential step (Knuth's MMIX constants).
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            result.swapAt(index, Int((state >> 33) % UInt64(index + 1)))
        }
        if count > 1, result == Array(0..<count) { result.swapAt(0, 1) }
        return result
    }

    /// The seed of one step of one lesson. Not `hashValue`, which changes on every launch.
    static func seed(lessonID: String, step: Int) -> UInt64 {
        lessonID.utf8.reduce(UInt64(5381)) { $0 &* 33 &+ UInt64($1) } &+ UInt64(step) &* 7919
    }
}
