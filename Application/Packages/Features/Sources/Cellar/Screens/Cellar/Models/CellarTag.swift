import Core
import Foundation

/// The one tag of every entry, from its status and verdict (CELLAR-R01a).
enum CellarTag: String, CaseIterable, Sendable {
    case yes, maybe, no, notYet

    init(_ entry: CellarEntry) {
        switch (entry.status, entry.verdict) {
        case (.tasted, .yes): self = .yes
        case (.tasted, .maybe): self = .maybe
        case (.tasted, .no): self = .no
        // A tasted entry always has a verdict; one without counts as not tasted yet.
        case (.tasted, nil), (.wantToTry, _): self = .notYet
        }
    }

    init(_ verdict: Verdict) {
        switch verdict {
        case .yes: self = .yes
        case .maybe: self = .maybe
        case .no: self = .no
        }
    }
}
