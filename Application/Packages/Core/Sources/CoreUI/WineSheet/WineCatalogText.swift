import Foundation

public enum WineCatalogText {
    public static func editorial(_ text: String) -> String {
        Bundle.module.localizedString(forKey: text, value: text, table: "WineEditorial")
    }

    /// Translate whole aroma terms for display. Keep the wording of unrecognized segments.
    public static func notes(_ text: String?) -> String {
        guard let text else { return "" }
        let delimiters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "."))
        return text.components(separatedBy: ",").map { segment in
            let term = segment.trimmingCharacters(in: delimiters)
            guard !term.isEmpty, let range = segment.range(of: term) else { return segment }
            let key = term.lowercased()
            let translation = Bundle.module.localizedString(forKey: key, value: key, table: "WineAromas")
            guard translation != key else { return segment }
            let label = term.first?.isUppercase == true
                ? translation.prefix(1).uppercased() + translation.dropFirst()
                : translation
            return segment.replacingCharacters(in: range, with: label)
        }.joined(separator: ",")
    }
}
