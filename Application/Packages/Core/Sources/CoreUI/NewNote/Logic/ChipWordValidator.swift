import Core
import Foundation

/// What becomes of a word typed in a chip sheet when "Add" is tapped (CELLAR-R18a).
public enum ChipWordResult: Equatable, Sendable {
    /// The word as the note writes it: the list's own spelling, or the typed word tidied.
    case accepted(String)
    /// Close to one of the list's: "Did you mean Cabernet Sauvignon?".
    case didYouMean(String)
    case rejected(ChipWordRejection)
}

public enum ChipWordRejection: Equatable, Sendable {
    /// Digits, symbols, a single letter: no name at all.
    case notAWord
    /// The model on the phone says it is not one.
    case unknown
    /// Not in UVVA's lists, and the model cannot run on this phone; `reason` says why, for debug builds.
    case modelUnavailable(reason: String)
    /// Not in UVVA's lists, and the model gave no answer this time; `reason` says why, for debug builds.
    case failed(reason: String)
}

extension ChipWordRejection {
    /// Why the model gave no answer, for debug builds; nil when it answered or was not asked.
    var debugReason: String? {
        switch self {
        case let .modelUnavailable(reason), let .failed(reason): reason
        case .notAWord, .unknown: nil
        }
    }
}

/// Checks a typed word against what UVVA knows, then against the model on the phone (CELLAR-R18a):
///
/// 1. A name is letters: digits and symbols are turned down at once.
/// 2. The list's own value, whatever the case and the accents, or as the phone's language writes it ("goiaba" for
///    Guava), is taken as the list writes it.
/// 3. One or two letters off a value of the list asks "Did you mean …?".
/// 4. Anything else goes to the model; with no model, it is turned down.
struct ChipWordValidator: Sendable {
    /// The values the list has, as they are stored.
    var known: [String]
    var kind: ChipWordKind
    /// How a stored value reads in the phone's language: an aroma is stored in English.
    var display: @Sendable (String) -> String = { $0 }

    /// The longest name taken: a dish may be a few words.
    static let maxLength = 60

    func validate(_ typed: String, checker: any ChipWordChecking) async -> ChipWordResult {
        if let local = listed(typed) { return local }
        guard let word = Self.cleaned(typed) else { return .rejected(.notAWord) }
        switch await checker.check(word, as: kind) {
        case .valid: return .accepted(Self.written(word, as: kind))
        case .invalid: return .rejected(.unknown)
        case let .unavailable(reason): return .rejected(.modelUnavailable(reason: reason))
        case let .failed(reason): return .rejected(.failed(reason: reason))
        }
    }

    /// What the lists alone decide; nil when only the model can.
    func listed(_ typed: String) -> ChipWordResult? {
        guard let word = Self.cleaned(typed) else { return .rejected(.notAWord) }
        let key = Self.folded(word)
        if let found = known.first(where: { Self.folded($0) == key || Self.folded(display($0)) == key }) {
            return .accepted(found)
        }
        guard let tolerance = Self.tolerance(for: key) else { return nil }
        var best: (value: String, distance: Int)?
        for value in known {
            let distance = min(Self.distance(key, Self.folded(value)), Self.distance(key, Self.folded(display(value))))
            if distance <= tolerance, distance < (best?.distance ?? .max) { best = (value, distance) }
        }
        return best.map { .didYouMean($0.value) }
    }

    /// The word with its spaces tidied; nil for what is no name.
    static func cleaned(_ typed: String) -> String? {
        let word = typed.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let allowed = CharacterSet.letters.union(.nonBaseCharacters).union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'’&.,()/"))
        guard word.count <= maxLength,
              word.unicodeScalars.filter(CharacterSet.letters.contains).count >= 2,
              word.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        return word
    }

    /// "Touriga nacional" → "Touriga Nacional" for a name; "goiaba" → "Goiaba" for an aroma or a dish.
    static func written(_ word: String, as kind: ChipWordKind) -> String {
        switch kind {
        case .aroma, .pairing:
            return word.prefix(1).uppercased() + word.dropFirst()
        case .grape, .region, .appellation:
            let small: Set<String> = ["de", "da", "do", "das", "dos", "di", "del", "della", "du", "des", "la", "le",
                                      "y", "e", "et", "von", "am", "an", "der"]
            return word.split(separator: " ").enumerated().map { index, part in
                let lower = part.lowercased()
                if index > 0, small.contains(lower) { return lower }
                // An appellation's category stays as it is written: DOC, AVA, IGT.
                if part.count > 1, part == part.uppercased() { return String(part) }
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }.joined(separator: " ")
        }
    }

    /// Lowercase, no accents, words split on anything but letters: "Grüner-Veltliner" and "gruner veltliner" match.
    static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// How many letters may be off before "Did you mean …?" stops: none for a short word, where one letter makes
    /// another word.
    static func tolerance(for key: String) -> Int? {
        switch key.count {
        case ..<4: nil
        case 4...6: 1
        default: 2
        }
    }

    /// The letters to change, add or take out to turn one into the other (Levenshtein).
    static func distance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs), b = Array(rhs)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }
}
