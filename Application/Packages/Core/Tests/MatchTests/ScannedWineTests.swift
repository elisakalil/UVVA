import Core
import Match
import Testing

struct ScannedWineTests {
    // MARK: CELLAR-R23 · Preencher à mão / vinho fora do catálogo

    @Test func CELLAR_R23_scannedWine_keepsWhatWasReadAndTheEstimatedMap() {
        let facts = LabelFacts(name: " Vinha Imaginária ", producer: "Monte da Urze", vintage: 2022, type: "Red",
                               appellation: "Douro", region: "Douro", country: "Portugal",
                               grapes: ["Touriga Nacional"], alcohol: 13.5)
        let map = PalateMap([.tannin: 7])
        let wine = ScannedWine.make(facts, profile: map)
        #expect(wine.id == "monte-da-urze-vinha-imaginaria-2022")
        #expect(wine.name == "Vinha Imaginária")
        #expect(wine.origin == "Douro, Portugal")
        #expect(wine.classification == "Douro · 13.5% abv")
        #expect(wine.profile == map)
        #expect(wine.grapes == ["Touriga Nacional"])
    }

    @Test func CELLAR_R23_onlyTheName_isEnough() {
        let wine = ScannedWine.make(LabelFacts(name: "Ponto Forte"), profile: PalateMap([:]))
        #expect(wine.id == "ponto-forte")
        #expect(wine.origin == "")
        #expect(wine.classification == "")
        #expect(wine.type == "")
    }

    @Test func modelFacts_fillTheirGapsFromTheParser() {
        let model = LabelFacts(name: "Ponto Forte", vintage: 2024, titleLines: ["Ponto Forte"])
        let parser = LabelFacts(name: "PONTO", producer: "Ravasqueira", vintage: 2023, grapes: ["Syrah"],
                                alcohol: 14, titleLines: ["PONTO", "Ponto Forte"])
        let merged = model.filling(from: parser)
        #expect(merged.name == "Ponto Forte")
        #expect(merged.producer == "Ravasqueira")
        #expect(merged.vintage == 2024)
        #expect(merged.grapes == ["Syrah"])
        #expect(merged.alcohol == 14)
        #expect(merged.titleLines == ["Ponto Forte", "PONTO"])
    }

    @Test func CELLAR_R17_scannedWine_keepsTheNotesPairingsAndServing() {
        let facts = LabelFacts(name: "Vinha Imaginária", notes: ["Plum", "Black pepper"],
                               pairings: ["Grilled lamb"], serving: 16...18)
        let wine = ScannedWine.make(facts, profile: PalateMap([:]))
        #expect(wine.note == "Plum, Black pepper")
        #expect(wine.pairings == ["Grilled lamb"])
        #expect(wine.serving == 16...18)
    }

    @Test func modelNotes_comeFirst_parserServingFillsTheGap() {
        let model = LabelFacts(name: "X", notes: ["Plum"], pairings: [])
        let parser = LabelFacts(name: "X", notes: ["Cherry"], pairings: ["Cheese"], serving: 14...16)
        let merged = model.filling(from: parser)
        #expect(merged.notes == ["Plum"])
        #expect(merged.pairings == ["Cheese"])
        #expect(merged.serving == 14...16)
    }
}
