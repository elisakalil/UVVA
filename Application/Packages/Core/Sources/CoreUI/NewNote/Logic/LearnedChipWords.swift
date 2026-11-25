import Core
import Foundation

/// The words this person typed and UVVA took (CELLAR-R18a), kept on the phone: they show among the suggestions of
/// the next notes, and the list no longer needs the model for them. They reach the public catalog only with a wine,
/// and only once another person reads the same (`CatalogMerge`).
@MainActor
final class LearnedChipWords {
    private let defaults: UserDefaults
    private static let prefix = "learnedChipWords."
    /// Enough for every word a person types; the oldest go first.
    static let limit = 300

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The words of a kind, the latest first.
    func words(_ kind: ChipWordKind) -> [String] {
        defaults.stringArray(forKey: Self.prefix + kind.rawValue) ?? []
    }

    func learn(_ word: String, as kind: ChipWordKind) {
        let key = word.lowercased()
        let kept = words(kind).filter { $0.lowercased() != key }
        defaults.set(Array(([word] + kept).prefix(Self.limit)), forKey: Self.prefix + kind.rawValue)
    }
}
