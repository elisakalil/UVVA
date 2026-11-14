import Foundation

/// The public catalog's record types and fields in CloudKit (ARCHITECTURE §3.2), shared by the app and the robot
/// (`Application/Robot`), so both write and read the same names.
public enum CatalogSchema {
    /// A wine of the catalog. recordName: the wineKey. Written only by the robot.
    public enum Wine {
        public static let type = "CatalogWine"
        /// `CatalogWineData` as JSON.
        public static let data = "data"
        /// `active`, or `removed` for a wine that left the catalog, so the delta sync takes it off the phones.
        public static let status = "status"
        /// `CatalogWineData.searchTokens`: the words a label is looked up by. Queryable.
        public static let tokens = "tokens"
        public static let active = "active"
        public static let removed = "removed"
    }

    /// The whole catalog in one file, for a phone that has none of it yet. One record, written only by the robot.
    public enum Snapshot {
        public static let type = "CatalogSnapshot"
        public static let recordName = "current"
        /// A hash of the wines file: a new value means a new snapshot.
        public static let version = "version"
        /// When the robot's run that wrote it started. Every `CatalogWine` changed after it is in the delta.
        public static let builtAt = "builtAt"
        public static let wineCount = "wineCount"
        /// `QualityPrevalence` as JSON, measured on these wines (CELLAR-R30).
        public static let prevalence = "prevalence"
        /// `CatalogWinesFile` as zlib-compressed JSON (an asset).
        public static let wines = "wines"
        /// The robot's own state, zlib-compressed JSON (an asset). The app never reads it.
        public static let state = "state"
    }

    /// What one user read on one wine's label: only the wine's facts, never a photo, a note or a verdict.
    /// recordName: SHA-256 of wineKey and user, so each user has one per wine and a new reading replaces it.
    /// Written by the user who read it; only the robot and its creator can read it.
    public enum Contribution {
        public static let type = "WineContribution"
        /// Queryable.
        public static let wineKey = "wineKey"
        /// The app's user id, to find a user's own contributions when the account is deleted. Queryable.
        public static let contributor = "contributor"
        /// `CatalogWineData` as JSON.
        public static let data = "data"
    }

    /// The most wines a phone keeps (ARCHITECTURE §4.1). Over it, those furthest from the user's palate leave it;
    /// a label of one of them is still found, as the scan then asks the public catalog.
    public static let deviceCap = 50_000

    /// The wine types the catalog accepts (`WINE_TYPES` in `pack_content.py`).
    public static let wineTypes: Set<String> = ["Red", "White", "Rosé", "Sparkling", "Fortified"]
}
