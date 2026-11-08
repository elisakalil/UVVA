import Foundation
import SwiftData

/// One wine in the Cellar, in the Personal store (ARCHITECTURE §2.1, `CellarEntry`; CELLAR.md §2).
/// It keeps its own copy of the wine's facts, so it still reads when the wine is not in the Content store.
/// CloudKit: every field has a default and nothing is unique; the store avoids duplicates by wineKey.
@Model
public final class CellarEntryEntity {
    public var wineKey = ""
    public var name = ""
    public var producer = ""
    public var vintage: Int?
    public var type = ""
    public var origin = ""
    /// The region and country of the wine, for the Cellar's filters and numbers (CELLAR-R04, R10).
    public var region: String?
    public var country: String?
    public var grapes: [String] = []
    public var alcohol: Double?
    public var classification = ""
    /// `tasted` or `wantToTry` (CELLAR-R01).
    public var status = Status.wantToTry.rawValue
    /// `yes`, `maybe` or `no`; only when tasted.
    public var verdict: String?
    public var note: String?
    @Attribute(.externalStorage) public var photoFront: Data?
    @Attribute(.externalStorage) public var photoBack: Data?
    public var createdAt = Date.distantPast
    public var updatedAt = Date.distantPast

    public enum Status: String {
        case tasted, wantToTry
    }

    init(wineKey: String, status: Status, date: Date) {
        self.wineKey = wineKey
        self.status = status.rawValue
        self.createdAt = date
        self.updatedAt = date
    }
}
