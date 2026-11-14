import Foundation

/// The catalog as the label reading needs it (CELLAR-R17).
public protocol LabelCatalogRepository: Sendable {
    /// Every wine on the phone, to look a label up and to estimate the map of a wine that is not there.
    func allWines() async throws -> [Wine]
    /// Keeps a scanned wine that was not in the catalog, so its note and the map find it like any other. A wine
    /// scanned before gains the grapes, notes and pairings this reading added; a catalog wine is left as it is.
    func addScanned(_ wine: Wine) async throws
    /// The wines of the public catalog that share any of these words (`WineText.significantTokens`) with their name
    /// or producer, for a label the phone's catalog does not find; they are kept on the phone from then on.
    func publicWines(sharing tokens: Set<String>) async throws -> [Wine]
    /// A note deleted (CELLAR-R28): a wine only its scan brought leaves the phone with every reading of it, and
    /// nothing read of the wine is sent to the public catalog any more. A catalog wine stays.
    func forgetScanned(_ wineKey: String) async throws
}

public extension LabelCatalogRepository {
    func publicWines(sharing tokens: Set<String>) async throws -> [Wine] { [] }
    func forgetScanned(_ wineKey: String) async throws {}
}
