import Foundation
import Testing
@testable import Core

struct WineKeyTests {
    // MARK: CELLAR-R13a · O mesmo vinho

    @Test func CELLAR_R13a_key_isTheSlugOfProducerNameAndVintage() {
        #expect(WineKey.make(producer: "Isole e Olena", name: "Chianti Classico", vintage: 2010)
            == "isole-e-olena-chianti-classico-2010")
    }

    @Test func CELLAR_R13a_accentsAndCase_doNotMakeAnotherWine() {
        #expect(WineKey.make(producer: "Ravasqueira", name: "Ponto Forte", vintage: 2024)
            == WineKey.make(producer: "RAVASQUEIRA", name: "Pontó Forté", vintage: 2024))
    }

    @Test func CELLAR_R13a_anotherVintage_isAnotherWine() {
        #expect(WineKey.make(producer: "Ravasqueira", name: "Ponto Forte", vintage: 2024)
            != WineKey.make(producer: "Ravasqueira", name: "Ponto Forte", vintage: 2023))
    }

    @Test func CELLAR_R13a_noVintageOrProducer_isLeftOut() {
        #expect(WineKey.make(producer: "", name: "Ponto Forte", vintage: nil) == "ponto-forte")
        #expect(WineKey.make(producer: "Château Musar", name: "Rouge", vintage: nil) == "chateau-musar-rouge")
    }

    @Test func CELLAR_R13a_symbolsAndOtherScripts_separateWords() {
        #expect(WineKey.make(producer: "Domaine d'Aupilhac", name: "Lou Maset® ΑΒΓ", vintage: 2019)
            == "domaine-d-aupilhac-lou-maset-2019")
    }

    /// Every packed wine has the key `pack_content.py` gave it, so a scanned wine finds its catalog twin.
    @Test(.enabled(if: FileManager.default.fileExists(atPath: Self.wines.path)))
    func CELLAR_R13a_sameKeyAsThePackedCatalog() throws {
        struct Packed: Decodable { var id: String; var producer: String; var name: String; var vintage: Int? }
        let packed = try JSONDecoder().decode([Packed].self, from: Data(contentsOf: Self.wines))
        let different = packed.filter { WineKey.make(producer: $0.producer, name: $0.name, vintage: $0.vintage) != $0.id }
        #expect(packed.count > 1000)
        #expect(different.map(\.id) == [])
    }

    static let wines = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // CoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Core
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // Application
        .appending(path: "Data/UVVAWines.json")
}
