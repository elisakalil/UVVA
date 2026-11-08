import Foundation

/// The catalog as the label reading needs it (CELLAR-R17).
public protocol LabelCatalogRepository: Sendable {
    /// Every wine on the phone, to look a label up and to estimate the map of a wine that is not there.
    func allWines() async throws -> [Wine]
    /// Keeps a scanned wine that was not in the catalog, so its note and the map find it like any other. A wine
    /// already there is left as it is.
    func addScanned(_ wine: Wine) async throws
}
