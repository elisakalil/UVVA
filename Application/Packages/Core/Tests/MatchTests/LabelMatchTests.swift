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

    // MARK: CELLAR-R17 · As fontes somam-se

    @Test func CELLAR_R17_confidentMatch_addsWhatTheLabelHasThatTheCatalogDoesNot() throws {
        var known = wine("Ravasqueira", "Ponto Forte", 2024)
        known.grapes = ["Syrah"]
        known.note = "Violet, plum."
        known.pairings = ["Roast lamb"]
        known.serving = 16...18
        let facts = LabelFacts(vintage: 2024, grapes: ["syrah", "Touriga Nacional"], alcohol: 13,
                               titleLines: ["Ponto Forte", "Ravasqueira"], notes: ["plum", "Black pepper"],
                               pairings: ["roast lamb", "Beef stew"], serving: 14...16)
        let result = try #require(LabelMatch.best(for: facts, in: LabelCatalogIndex(wines: [known])))
        #expect(result.isConfident)
        // The catalog's first, then what is new, whatever its case.
        #expect(result.wine.grapes == ["Syrah", "Touriga Nacional"])
        #expect(result.wine.note == "Violet, plum, Black pepper")
        #expect(result.wine.pairings == ["Roast lamb", "Beef stew"])
        // What cannot be added up stays the catalog's.
        #expect(result.wine.serving == 16...18)
        #expect(result.wine.alcohol == 14)
    }

    @Test func CELLAR_R17_confidentMatch_takesTheLabelsServing_whenTheCatalogHasNone() throws {
        let facts = LabelFacts(vintage: 2024, titleLines: ["Ponto Forte", "Ravasqueira"], serving: 14...16)
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.wine.serving == 14...16)
        #expect(result.wine.note == nil)
    }

    @Test func CELLAR_R17_unsureMatch_isLeftAsItIs() throws {
        let facts = LabelFacts(titleLines: ["Ravasqueira"], notes: ["Plum"])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(!result.isConfident)
        #expect(result.wine.note == nil)
    }

    // MARK: CELLAR-R30 · Certificação

    @Test func CELLAR_R30_confidentMatch_addsTheCertificationTheCatalogDoesNotHave() throws {
        let gold = WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)
        let facts = LabelFacts(vintage: 2024, appellation: "Vinho Regional Alentejano",
                               titleLines: ["Ponto Forte", "Ravasqueira"], designation: "Reserva", awards: [gold])
        let result = try #require(LabelMatch.best(for: facts, in: index))
        #expect(result.isConfident)
        #expect(result.wine.appellation == "Vinho Regional Alentejano")
        #expect(result.wine.designation == "Reserva")
        #expect(result.wine.awards == [gold])
    }

    @Test func CELLAR_R30_confidentMatch_keepsTheCatalogsCertification_andAddsNewAwards() throws {
        let gold = WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)
        let silver = WineAward(competition: "Mundus Vini", medal: .silver, year: 2022)
        var known = wine("Ravasqueira", "Ponto Forte", 2024)
        known.classification = "Alentejo DOC · 14% abv"
        known.designation = "Grande Reserva"
        known.awards = [gold]
        let facts = LabelFacts(vintage: 2024, appellation: "Vinho Regional Alentejano",
                               titleLines: ["Ponto Forte", "Ravasqueira"], designation: "Reserva",
                               awards: [gold, silver])
        let result = try #require(LabelMatch.best(for: facts, in: LabelCatalogIndex(wines: [known])))
        #expect(result.wine.appellation == "Alentejo DOC")
        #expect(result.wine.designation == "Grande Reserva")
        #expect(result.wine.awards == [gold, silver])
    }

    @Test func CELLAR_R30_aReading_addsTheCategoryToTheSamePlace() throws {
        var known = wine("Ravasqueira", "Ponto Forte", 2024)
        known.classification = "Alentejo · 14% abv"
        let facts = LabelFacts(vintage: 2024, appellation: "Vinho Regional Alentejano",
                               titleLines: ["Ponto Forte", "Ravasqueira"])
        let sameplace = LabelFacts(vintage: 2024, appellation: "Alentejo DOC", titleLines: ["Ponto Forte", "Ravasqueira"])
        let index = LabelCatalogIndex(wines: [known])
        // Another place is not this one's category.
        #expect(try #require(LabelMatch.best(for: facts, in: index)).wine.classification == "Alentejo · 14% abv")
        #expect(try #require(LabelMatch.best(for: sameplace, in: index)).wine.classification == "Alentejo DOC · 14% abv")
    }
}
