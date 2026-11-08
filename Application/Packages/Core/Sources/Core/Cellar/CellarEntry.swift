import Foundation

/// One wine in the Cellar, with its own copy of the wine's facts (CELLAR.md §2).
public struct CellarEntry: Identifiable, Equatable, Sendable {
    /// The wineKey.
    public var id: String
    public var name: String
    public var producer: String
    /// Nil for wines without a vintage.
    public var vintage: Int?
    /// Red, White, Rosé, Sparkling or Fortified.
    public var type: String
    public var region: String?
    public var country: String?
    /// The appellation and country, "Chianti Classico, Italy".
    public var origin: String
    public var grapes: [String]
    public var status: CellarEntryStatus
    /// Only when tasted.
    public var verdict: Verdict?
    /// "Your note", kept for the user only (CELLAR-R20).
    public var note: String?
    public var alcohol: Double?
    /// The appellation and strength, "Rioja DOCa · 13.5% abv".
    public var classification: String
    /// The front and back labels, when the wine was photographed.
    public var photoFront: Data?
    public var photoBack: Data?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: String, name: String, producer: String = "", vintage: Int? = nil, type: String = "",
                region: String? = nil, country: String? = nil, origin: String = "", grapes: [String] = [],
                status: CellarEntryStatus, verdict: Verdict? = nil, note: String? = nil, alcohol: Double? = nil,
                classification: String = "", photoFront: Data? = nil, photoBack: Data? = nil,
                createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.producer = producer
        self.vintage = vintage
        self.type = type
        self.region = region
        self.country = country
        self.origin = origin
        self.grapes = grapes
        self.status = status
        self.verdict = verdict
        self.note = note
        self.alcohol = alcohol
        self.classification = classification
        self.photoFront = photoFront
        self.photoBack = photoBack
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}
