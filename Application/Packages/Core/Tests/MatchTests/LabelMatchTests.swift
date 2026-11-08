import Core
import Match
import Testing

struct LabelMatchTests {
    private func flat(_ value: Double) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
    }

    private func wine(_ producer: String, _ name: String, _ vintage: Int?, type: String = "Red") -> Wine {
        Wine(id: WineKey.make(producer: producer, name: name, vintage: vintage), name: name, producer: producer,
             vintage: vintage, type: type, origin: "", alcohol: 14, profile: flat(5))
    }

    private var index: LabelCatalogIndex {
        LabelCatalogIndex(wines: [
            wine("Ravasqueira", "Ponto Forte", 2024),
            wine("Ravasqueira", "Ponto Forte", 2022),
            wine("Ravasqueira", "Reserva da Família", 2020),
            wine("Quinta do Crasto", "Reserva Old Vines", 2019),
            wine("Quinta do Crasto", "Douro", 2021),
            wine("Château Musar", "Rouge", 2016),
            wine("Château Musar", "Blanc", 2016, type: "White")
        ])
    }

    // MARK: CELLAR-R17 · Leitura

    @Test func CELLAR_R17_sameWineAndVintage_isFound() throws {
        let facts = LabelFacts(vintage: 2024, titleLines: ["Ponto Forte", "RAVASQUEIRA"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.wine.id == "ravasqueira-ponto-forte-2024")
        #expect(result.isConfident)
    }

    @Test func CELLAR_R17_noisyText_isStillFound() throws {
        let facts = LabelFacts(vintage: 2016, type: "Red", titleLines: ["CHATEAU MUSAR", "Rouge", "Bekaa Valley Lebanon"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.wine.id == "chateau-musar-rouge-2016")
        #expect(result.isConfident)
    }

    @Test func CELLAR_R17_type_tellsTwoWinesOfTheSameProducerApart() throws {
        let facts = LabelFacts(vintage: 2016, type: "White", titleLines: ["Château Musar"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.wine.id == "chateau-musar-blanc-2016")
        #expect(!result.isConfident)
    }

    @Test func CELLAR_R13a_anotherVintage_isTheSameWineWithItsOwnKey() throws {
        let facts = LabelFacts(vintage: 2023, alcohol: 13.5, titleLines: ["Ponto Forte", "Ravasqueira"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.wine.id == "ravasqueira-ponto-forte-2023")
        #expect(result.wine.vintage == 2023)
        #expect(result.wine.alcohol == 13.5)
        #expect(result.wine.profile == flat(5))
    }

    @Test func CELLAR_R17_wineNamedAfterItsAppellation_isFound() throws {
        let facts = LabelFacts(producer: "Quinta do Crasto", vintage: 2021, appellation: "Douro",
                               titleLines: ["Quinta do Crasto"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.wine.id == "quinta-do-crasto-douro-2021")
        #expect(result.isConfident)
    }

    @Test func CELLAR_R17_onlyTheProducer_isNotConfident() throws {
        let facts = LabelFacts(titleLines: ["Ravasqueira"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(!result.isConfident)
    }

    @Test func CELLAR_R17_unknownWine_isNotFound() {
        #expect(LabelMatch.best(for: LabelFacts(titleLines: ["Pêra-Manca", "Cartuxa"]), in: index) == nil)
        #expect(LabelMatch.best(for: LabelFacts(), in: index) == nil)
    }
}
