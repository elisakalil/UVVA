import Core
import Foundation
import Match
import Testing

/// The parser and the lookup against the real packed catalog (Application/Data/UVVAWines.json).
struct LabelCatalogTests {
    static let file = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // MatchTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Core
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // Application
        .appending(path: "Data/UVVAWines.json")

    private struct Packed: Decodable {
        var id, name, producer, origin, type: String
        var vintage: Int?
        var region, country: String?
        var grapes: [String]?
        var map: [[String: Double]]
    }

    private static func catalog() throws -> [Wine] {
        try JSONDecoder().decode([Packed].self, from: Data(contentsOf: file)).map { packed in
            let values = packed.map.reduce(into: [PalateAxis: Double]()) { result, entry in
                for (key, value) in entry { if let axis = PalateAxis(rawValue: key) { result[axis] = value } }
            }
            return Wine(id: packed.id, name: packed.name, producer: packed.producer, vintage: packed.vintage,
                        type: packed.type, origin: packed.origin, region: packed.region, country: packed.country,
                        grapes: packed.grapes ?? [], profile: PalateMap(values))
        }
    }

    @Test(.enabled(if: FileManager.default.fileExists(atPath: Self.file.path)))
    func CELLAR_R17_realLabel_findsItsCatalogWine() throws {
        let wines = try Self.catalog()
        let label = LabelText([
            LabelLine("ISOLE E OLENA", height: 0.08),
            LabelLine("CHIANTI CLASSICO", height: 0.06),
            LabelLine("Denominazione di Origine Controllata e Garantita", height: 0.02),
            LabelLine("2010", height: 0.03),
            LabelLine("Sangiovese, Canaiolo", side: .back),
            LabelLine("13,5% vol 750 ml", side: .back),
            LabelLine("Prodotto in Italia", side: .back)
        ])
        let facts = LabelParser.parse(label, vocabulary: LabelVocabulary(wines: wines), currentYear: 2026)
        #expect(facts.type == "Red")
        #expect(facts.country == "Italy")
        #expect(facts.grapes.contains("Sangiovese"))
        #expect(facts.alcohol == 13.5)

        let result = try #require(LabelMatch.best(for: facts, in: LabelCatalogIndex(wines: wines)))
        #expect(result.wine.id == "isole-e-olena-chianti-classico-2010")
        #expect(result.isConfident)
    }

    @Test(.enabled(if: FileManager.default.fileExists(atPath: Self.file.path)))
    func CELLAR_R17_unknownLabel_getsAnEstimatedMap() throws {
        let wines = try Self.catalog()
        let label = LabelText([
            LabelLine("Vinha da Urze Imaginária", height: 0.1),
            LabelLine("Touriga Nacional", side: .back),
            LabelLine("Vinho Tinto · Douro", side: .back)
        ])
        let facts = LabelParser.parse(label, vocabulary: LabelVocabulary(wines: wines), currentYear: 2026)
        #expect(facts.name == "Vinha da Urze Imaginária")
        #expect(facts.type == "Red")
        let match = LabelMatch.best(for: facts, in: LabelCatalogIndex(wines: wines))
        #expect(match?.isConfident != true)
        let map = try #require(ProfileEstimate.estimate(grapes: facts.grapes, type: facts.type, region: facts.region,
                                                        in: wines))
        #expect(map[.tannin] > 0)
    }
}
