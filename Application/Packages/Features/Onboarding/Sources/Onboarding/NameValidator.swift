import Foundation

/// ONB-R15, R16: at least two letters once the ends are trimmed.
enum NameValidator {
    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValid(_ name: String) -> Bool {
        normalized(name).count >= 2
    }
}
