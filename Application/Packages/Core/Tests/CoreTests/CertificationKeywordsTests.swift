import Testing
@testable import Core

/// The words of a label's certification (CELLAR-R30).
struct CertificationKeywordsTests {
    @Test(arguments: [
        ("Douro DOC", "Douro", "DOC", AppellationTier.protected),
        ("Vinho Regional Lisboa", "Lisboa", "Vinho Regional", .regional),
        ("Chianti Classico D.O.C.G.", "Chianti Classico", "DOCG", .top),
        ("Appellation Margaux Contrôlée", "Margaux", "AOC", .protected),
        ("Rioja DOCa", "Rioja", "DOCa", .top),
        ("Bourgogne Premier Cru", "Bourgogne", "Premier Cru", .top)
    ])
    func CELLAR_R30_appellation_splitsIntoPlaceAndCategory(text: String, name: String, category: String,
                                                           tier: AppellationTier) {
        let split = CertificationKeywords.split(text)
        #expect(split.name == name)
        #expect(split.category == category)
        #expect(split.tier == tier)
    }

    @Test func CELLAR_R30_aPlaceAlone_hasNoCategory() {
        let split = CertificationKeywords.split("Colchagua Valley")
        #expect(split.name == "Colchagua Valley")
        #expect(split.category == nil)
        #expect(split.tier == nil)
    }

    @Test func CELLAR_R30_categoryWrittenInFull_isFound() {
        let found = CertificationKeywords.category(in: "DOURO · DENOMINAÇÃO DE ORIGEM CONTROLADA")
        #expect(found?.category == "DOC")
        #expect(found?.tier == .protected)
    }

    @Test func CELLAR_R30_legalTerm_isWhatTheLawMakesOfItWhereTheWineIsFrom() {
        #expect(CertificationKeywords.designation(in: "GRANDE RESERVA") == "Grande Reserva")
        #expect(CertificationKeywords.designation(in: "Casillero del Diablo Reservado") == nil)
        #expect(CertificationKeywords.strength(of: "Grande Reserva", country: "Portugal") == .strong)
        #expect(CertificationKeywords.strength(of: "Gran Reserva", country: "Chile") == .weak)
        #expect(CertificationKeywords.strength(of: "Riserva", country: "Italy") == .strong)
        #expect(CertificationKeywords.strength(of: "Crianza", country: "Spain") == .aged)
        #expect(CertificationKeywords.strength(of: "Reserve", country: "United States") == .weak)
    }

    @Test func CELLAR_R30_competition_takesItsLongestName() {
        #expect(CertificationKeywords.source(in: "DECANTER WORLD WINE AWARDS 2023")?.name == "Decanter World Wine Awards")
        #expect(CertificationKeywords.source(in: "James Suckling")?.isCritic == true)
        #expect(CertificationKeywords.medal(in: "MÉDAILLE D'OR") == .gold)
        #expect(CertificationKeywords.medal(in: "a golden colour") == nil)
    }

    @Test func CELLAR_R30_award_isKeptAsTextAndReadBack() throws {
        let gold = WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)
        #expect(gold.text == "Gold · Decanter World Wine Awards · 2023")
        #expect(WineAward(text: gold.text) == gold)
        let score = WineAward(competition: "James Suckling", points: 92)
        #expect(score.text == "92 pts · James Suckling")
        #expect(WineAward(text: score.text) == score)
        #expect(WineAward(text: "nothing") == nil)
        #expect(WineAward.Medal(title: "GOLD MEDAL") == .gold)
        #expect(WineAward.Medal(title: "Double Gold") == .doubleGold)
    }

    @Test func CELLAR_R30_awards_addUp_withoutRepeating() {
        let gold = WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)
        let same = WineAward(competition: "decanter world wine awards", medal: .gold, year: 2023)
        let silver = WineAward(competition: "Mundus Vini", medal: .silver)
        #expect([gold].adding([same, silver]) == [gold, silver])
    }

    @Test func CELLAR_R30_aKnownAppellation_gainsItsCategory_fromTheSamePlaceOnly() {
        #expect(CertificationKeywords.appellation(nil, adding: "Douro DOC") == "Douro DOC")
        #expect(CertificationKeywords.appellation("Lisboa", adding: "Vinho Regional Lisboa") == "Vinho Regional Lisboa")
        #expect(CertificationKeywords.appellation("Lisboa", adding: "Douro DOC") == "Lisboa")
        #expect(CertificationKeywords.appellation("Douro DOC", adding: "Douro DOP") == "Douro DOC")
    }
}
