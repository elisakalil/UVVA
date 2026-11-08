import Testing
@testable import Core

struct LabelParserTests {
    private let vocabulary = LabelVocabulary(
        grapeTypes: ["Syrah": "Red", "Sauvignon Blanc": "White", "Cabernet Sauvignon": "Red", "Touriga Nacional": "Red",
                     "Alicante Bouschet": "Red", "Chardonnay": "White"],
        appellationRegions: ["Vinho Regional Alentejano": "Alentejo", "Douro": "Douro", "Champagne": "Champagne",
                             "Porto": "Douro"],
        appellationTypes: ["Vinho Regional Alentejano": "Red", "Douro": "Red", "Champagne": "Sparkling",
                           "Porto": "Fortified"],
        regionCountries: ["Alentejo": "Portugal", "Douro": "Portugal", "Champagne": "France", "Tuscany": "Italy"],
        countries: ["Portugal", "France", "Italy"])

    private func parse(_ lines: [LabelLine]) -> LabelFacts {
        LabelParser.parse(LabelText(lines), vocabulary: vocabulary, currentYear: 2026)
    }

    // MARK: CELLAR-R17 · Leitura

    @Test func CELLAR_R17_frontAndBack_fillTheFacts() {
        let facts = parse([
            LabelLine("RAVASQUEIRA", height: 0.06),
            LabelLine("Ponto Forte", height: 0.12),
            LabelLine("2024", height: 0.04),
            LabelLine("Vinho Regional Alentejano", height: 0.03),
            LabelLine("Syrah · Alicante Bouschet", side: .back),
            LabelLine("13,5% vol   750 ml", side: .back),
            LabelLine("Produzido e engarrafado por Monte da Ravasqueira, Arraiolos", side: .back)
        ])
        #expect(facts.name == "Ponto Forte")
        #expect(facts.producer == "Monte da Ravasqueira")
        #expect(facts.vintage == 2024)
        #expect(facts.alcohol == 13.5)
        #expect(facts.appellation == "Vinho Regional Alentejano")
        #expect(facts.region == "Alentejo")
        #expect(facts.country == "Portugal")
        #expect(facts.grapes == ["Alicante Bouschet", "Syrah"])
        #expect(facts.type == "Red")
        #expect(facts.titleLines == ["Ponto Forte", "RAVASQUEIRA"])
    }

    @Test func CELLAR_R17_vintage_skipsFoundingDates() {
        #expect(parse([LabelLine("Since 1887"), LabelLine("Reserva 2019")]).vintage == 2019)
        #expect(parse([LabelLine("Desde 1887")]).vintage == nil)
    }

    @Test func CELLAR_R17_vintage_ignoresFutureYearsAndVolumes() {
        #expect(parse([LabelLine("2031"), LabelLine("750 ml")]).vintage == nil)
    }

    @Test func CELLAR_R17_alcohol_withPointOrComma() {
        #expect(parse([LabelLine("Alc. 14.5% by vol.")]).alcohol == 14.5)
        #expect(parse([LabelLine("12,5 % vol")]).alcohol == 12.5)
        #expect(parse([LabelLine("ALCOOL 13%")]).alcohol == 13)
    }

    @Test func CELLAR_R17_alcohol_ignoresGrapeShares() {
        #expect(parse([LabelLine("85% Syrah, 15% Cabernet Sauvignon")]).alcohol == nil)
        #expect(parse([LabelLine("85% Syrah"), LabelLine("13%")]).alcohol == 13)
    }

    @Test(arguments: [
        ("Vinho Tinto", "Red"), ("Vin Rouge", "Red"), ("Vino Rosso", "Red"), ("Branco", "White"), ("Vin Blanc", "White"),
        ("Bianco", "White"), ("Rosé", "Rosé"), ("Rosado", "Rosé"), ("Espumante Bruto", "Sparkling"), ("Brut", "Sparkling"),
        ("Prosecco", "Sparkling"), ("Tawny Port", "Fortified"), ("Jerez Oloroso", "Fortified")
    ])
    func CELLAR_R17_type_fromItsWord(text: String, type: String) {
        #expect(parse([LabelLine(text)]).type == type)
    }

    @Test func CELLAR_R17_type_fortifiedOrSparkling_winsOverColour() {
        #expect(parse([LabelLine("Porto Tinto")]).type == "Fortified")
        #expect(parse([LabelLine("Rosé Brut")]).type == "Sparkling")
    }

    @Test func CELLAR_R17_type_grapeNameIsNotAColour() {
        // "Blanc" here is the grape's, so the type comes from the grape itself.
        #expect(parse([LabelLine("Sauvignon Blanc")]).type == "White")
        #expect(parse([LabelLine("Sauvignon Blanc")]).grapes == ["Sauvignon Blanc"])
    }

    @Test func CELLAR_R17_type_fromTheAppellation_whenNoWord() {
        #expect(parse([LabelLine("Champagne")]).type == "Sparkling")
    }

    @Test func CELLAR_R17_grapes_longestNameFirst() {
        #expect(parse([LabelLine("Cabernet Sauvignon")]).grapes == ["Cabernet Sauvignon"])
    }

    @Test func CELLAR_R17_country_asTheLabelWritesIt() {
        #expect(parse([LabelLine("Prodotto in Italia")]).country == "Italy")
    }

    @Test func CELLAR_R17_producer_fromItsMark() {
        let facts = parse([LabelLine("Crasto", height: 0.1), LabelLine("Quinta do Crasto", height: 0.04),
                           LabelLine("Douro", height: 0.03)])
        #expect(facts.producer == "Quinta do Crasto")
        #expect(facts.name == "Crasto")
    }

    @Test func CELLAR_R17_titleLines_leaveOutWhatIsNotAName() {
        let facts = parse([LabelLine("DOURO", height: 0.2), LabelLine("Denominação de Origem Controlada", height: 0.1),
                           LabelLine("Touriga Nacional", height: 0.09), LabelLine("2019", height: 0.08),
                           LabelLine("Vinha Grande", height: 0.07)])
        #expect(facts.titleLines == ["Vinha Grande"])
        #expect(facts.producer == nil)
    }

    @Test func CELLAR_R21_nothingRead_isEmpty() {
        #expect(LabelText([LabelLine("  "), LabelLine("2019")]).isEmpty)
        #expect(!parse([]).hasName)
    }
}
