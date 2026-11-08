import Foundation

/// The wineKey (ARCHITECTURE §2.2): a slug of producer, name and vintage, the same as `wine_key` in
/// `Scripts/pack_content.py`, so a scanned wine gets the key the catalog would give it (CELLAR-R13a).
public enum WineKey {
    /// "Isole e Olena", "Chianti Classico", 2010 → "isole-e-olena-chianti-classico-2010". An empty part, or a
    /// wine without a vintage, is left out.
    public static func make(producer: String, name: String, vintage: Int?) -> String {
        let parts = [producer, name, vintage.map(String.init) ?? ""].filter { !$0.isEmpty }
        return WineText.tokens(parts.joined(separator: " ")).joined(separator: "-")
    }
}
