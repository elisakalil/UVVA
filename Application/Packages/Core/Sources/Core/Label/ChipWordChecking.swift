import Foundation

/// What a word typed in a chip sheet should name (CELLAR-R18a).
public enum ChipWordKind: String, CaseIterable, Sendable {
    case grape, aroma, pairing, region, appellation
}

/// The model on the phone's answer for a word UVVA's lists do not have.
public enum ChipWordVerdict: Equatable, Sendable {
    case valid
    case invalid
    /// The model cannot run on this phone: no iOS 26, Apple Intelligence off or not ready, a language it lacks.
    /// `reason` says which, in plain words, for debug builds.
    case unavailable(reason: String)
    /// The model runs here but gave no answer this time; `reason` says why, for debug builds.
    case failed(reason: String)
}

/// Asks the model on the phone (Foundation Models, iOS 26) whether a typed word is a real grape, aroma, dish,
/// region or appellation (CELLAR-R18a).
public protocol ChipWordChecking: Sendable {
    func check(_ word: String, as kind: ChipWordKind) async -> ChipWordVerdict
}

/// A phone with no model: nothing typed outside UVVA's lists can be checked.
public struct NoChipWordChecker: ChipWordChecking {
    public init() {}

    public func check(_ word: String, as kind: ChipWordKind) async -> ChipWordVerdict {
        .unavailable(reason: "No model on this phone.")
    }
}
