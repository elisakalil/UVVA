import Foundation
import SwiftData

/// Where the phone's copy of the public catalog stands (ARCHITECTURE §4.1). One record. It lives in the Content store,
/// so a store rebuilt from nothing also starts the catalog from the snapshot again.
@Model
public final class CatalogStateEntity {
    /// The latest change of the public catalog the phone has: the next sync asks for those after it. Nil until the
    /// first snapshot is in.
    public var lastChange: Date?
    /// When the phone last asked, to ask at most once a day.
    public var lastCheck: Date?
    public var snapshotVersion: String?
    /// `QualityPrevalence` of the last snapshot, as JSON.
    public var prevalence: Data?
    /// The wines scanned before the public catalog existed have been queued as contributions.
    public var queuedEarlierScans: Bool = false

    init() {}
}
