import Testing
@testable import Core

struct WineEvidenceTests {
    private let vocabulary = LabelVocabulary(
        grapeTypes: ["Syrah": "Red", "Touriga Nacional": "Red", "Alicante Bouschet": "Red", "Chardonnay": "White"],
        appellationRegions: ["Douro": "Douro", "Vinho Regional Alentejano": "Alentejo"],
        appellationTypes: ["Douro": "Red", "Vinho Regional Alentejano": "Red"],
        regionCountries: ["Alentejo": "Portugal", "Douro": "Portugal", "Lisboa": "Portugal"],
        countries: ["Portugal", "France", "Italy"])

    private func isWine(_ lines: [LabelLine]) -> Bool {
        let text = LabelText(lines)
        return WineEvidence.isWine(text, facts: LabelParser.parse(text, vocabulary: vocabulary, currentYear: 2026))
    }

    // MARK: CELLAR-R21a · Um vinho

    @Test func CELLAR_R21a_aWholeLabel_isAWine() {
        #expect(isWine([
            LabelLine("Ponto Forte", height: 0.12), LabelLine("RAVASQUEIRA"), LabelLine("2024"),
            LabelLine("Vinho Regional Alentejano"), LabelLine("Syrah · Alicante Bouschet", side: .back),
            LabelLine("13,5% vol   750 ml", side: .back), LabelLine("Contém sulfitos", side: .back)
        ]))
    }

    @Test func CELLAR_R21a_oneStrongSign_isEnough() {
        #expect(isWine([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("Touriga Nacional", side: .back)]))
        #expect(isWine([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("Alc. 12,5% by vol.", side: .back)]))
        #expect(isWine([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("Vinho tinto", side: .back)]))
        #expect(isWine([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("Espumante Bruto", side: .back)]))
    }

    @Test func CELLAR_R21a_threeWeakSigns_makeAWine() {
        // A producer's word, an appellation and its category, with no grape, no "% vol" and no word for wine.
        #expect(isWine([LabelLine("Quinta do Vale Imaginário", height: 0.1), LabelLine("Douro DOC")]))
    }

    // MARK: CELLAR-R21a · Outra coisa

    @Test func CELLAR_R21a_aSugarBag_isNotAWine() {
        #expect(!isWine([
            LabelLine("SIDUL", height: 0.14), LabelLine("Açúcar Branco", height: 0.1), LabelLine("1 kg"),
            LabelLine("Produzido por Sidul Açúcares, Lisboa", side: .back),
            LabelLine("Hidratos de carbono 100 g 38%", side: .back),
            LabelLine("Consumir de preferência antes de 12/2026", side: .back)
        ]))
    }

    @Test func CELLAR_R21a_aNameAlone_isNotAWine() {
        #expect(!isWine([LabelLine("Ponto Forte", height: 0.12), LabelLine("RAVASQUEIRA")]))
    }

    @Test func CELLAR_R21a_otherDrinks_withAlcoholOrAColour_areNotWines() {
        #expect(!isWine([LabelLine("Super Bock", height: 0.12), LabelLine("Cerveja Lager"), LabelLine("5,2% vol")]))
        #expect(!isWine([LabelLine("Vodka Imaginária", height: 0.12), LabelLine("Alc. 40% vol")]))
        #expect(!isWine([LabelLine("Sumo de Uva Tinta", height: 0.12), LabelLine("100% fruta")]))
    }

    @Test func CELLAR_R21a_aWordForWine_winsOverAnotherProduct() {
        // Port is fortified with brandy, and says so.
        #expect(isWine([LabelLine("Porto Imaginário", height: 0.12), LabelLine("Vinho do Porto"),
                        LabelLine("Vinho fortificado com brandy vínico", side: .back)]))
    }

    @Test func CELLAR_R21a_aBareOrStrongPercentage_isNotAWinesAlcohol() {
        #expect(LabelParser.labeledAlcohol(in: [LabelLine("Lípidos 20%")], within: WineEvidence.wineStrength) == nil)
        #expect(LabelParser.labeledAlcohol(in: [LabelLine("40% vol")], within: WineEvidence.wineStrength) == nil)
        #expect(LabelParser.labeledAlcohol(in: [LabelLine("13,5 % vol")], within: WineEvidence.wineStrength) == 13.5)
    }
}
