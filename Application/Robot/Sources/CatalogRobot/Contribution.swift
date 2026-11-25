import Core
import Foundation

/// What one user read on one wine's label (`WineContribution`).
public struct Contribution: Equatable, Sendable {
    public var wineKey: String
    /// The iCloud user who wrote it, from CloudKit: a user cannot pass for another.
    public var contributor: String
    public var wine: CatalogWineData
    public var created: Date
    public var modified: Date

    public init(wineKey: String, contributor: String, wine: CatalogWineData, created: Date, modified: Date) {
        self.wineKey = wineKey
        self.contributor = contributor
        self.wine = wine
        self.created = created
        self.modified = modified
    }

    init?(_ record: WebRecord) {
        guard let key = record.fields[CatalogSchema.Contribution.wineKey]?.string,
              let json = record.fields[CatalogSchema.Contribution.data]?.string,
              let wine = try? JSONDecoder().decode(CatalogWineData.self, from: Data(json.utf8)),
              let creator = record.creator else { return nil }
        self.init(wineKey: key, contributor: creator, wine: wine, created: record.created ?? .distantPast,
                  modified: record.modified ?? record.created ?? .distantPast)
    }
}

/// What a contribution must be to count, with no one to look at it: a wine as a label shows it, not text pasted to
/// spam the catalog.
public enum ContributionRules {
    /// The most contributions one user's day counts; the rest of that day waits for no one.
    public static let dailyLimit = 100
    static let maxText = 160
    static let maxItems = 20
    static let maxItem = 80

    public static func isValid(_ contribution: Contribution, now: Date = Date()) -> Bool {
        let wine = contribution.wine
        let year = Calendar(identifier: .gregorian).component(.year, from: now)
        let name = wine.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard contribution.wineKey == wine.id,
              wine.id == WineKey.make(producer: wine.producer, name: wine.name, vintage: wine.vintage),
              (2...maxText).contains(name.count), wine.producer.count <= maxText,
              wine.vintage.map({ (1900...year + 1).contains($0) }) ?? true,
              wine.type.isEmpty || CatalogSchema.wineTypes.contains(wine.type),
              wine.alcohol.map({ (3...25).contains($0) }) ?? true,
              wine.servingTemperature.map({ $0.min <= $0.max && $0.min >= 0 && $0.max <= 25 }) ?? true,
              wine.oakAging.map({ OakAging(rawValue: $0) != nil }) ?? true else {
            return false
        }
        let texts = [wine.name, wine.producer, wine.origin, wine.region ?? "", wine.country ?? "", wine.classification,
                     wine.designation ?? ""]
        let lists = [wine.grapes, wine.pairings, wine.awards ?? [], noteItems(wine), wine.oakWoods ?? []]
        guard texts.allSatisfy({ $0.count <= maxText }),
              lists.allSatisfy({ $0.count <= maxItems && $0.allSatisfy { $0.count <= maxItem } }) else { return false }
        return !(texts + lists.flatMap { $0 }).contains(where: looksLikeSpam)
    }

    /// Links and addresses are never on a label's facts.
    static func looksLikeSpam(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["http", "www.", ".com", "@", "<", ">"].contains { lower.contains($0) }
    }

    /// The valid contributions, at most `dailyLimit` of each user's on each day (the first ones written).
    public static func accepted(_ contributions: [Contribution], now: Date = Date()) -> [Contribution] {
        let calendar = Calendar(identifier: .gregorian)
        var perDay: [String: Int] = [:]
        return contributions.sorted { $0.created < $1.created }.filter { contribution in
            guard isValid(contribution, now: now) else { return false }
            let day = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: contribution.created)
            let bucket = "\(contribution.contributor)|\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
            perDay[bucket, default: 0] += 1
            return perDay[bucket]! <= dailyLimit
        }
    }

    static func noteItems(_ wine: CatalogWineData) -> [String] {
        wine.wine.noteItems
    }
}
