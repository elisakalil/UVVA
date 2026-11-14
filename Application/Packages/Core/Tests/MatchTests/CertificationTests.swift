import Core
import Testing
@testable import Match

/// The certificate of a wine and its "Top X%" (CELLAR-R30).
struct CertificationTests {
    /// Round numbers, so each case reads off the arithmetic.
    private let prevalence = QualityPrevalence(
        appellation: ["regional": 1.0, "protected": 0.9, "top": 0.2],
        designation: ["weak": 0.15, "aged": 0.07, "strong": 0.02],
        recognition: ["4": 0.005, "3": 0.02, "2": 0.05, "1": 0.1])

    private func wine(_ name: String = "Colossal", country: String = "Portugal", classification: String = "",
                      designation: String? = nil, awards: [WineAward] = [], insight: String? = nil,
                      notable: Bool = false) -> Wine {
        Wine(id: "w", name: name, origin: "", country: country, classification: classification,
             profile: PalateMap([:]), appellationInsight: insight, hasNotableAppellation: notable,
             designation: designation, awards: awards)
    }

    private func certificate(_ wine: Wine) -> WineCertificate? {
        Certification.make(for: wine, prevalence: prevalence)
    }

    @Test func CELLAR_R30_aWineWithNothing_hasNoCard() {
        #expect(certificate(wine()) == nil)
        #expect(certificate(wine(classification: "13.5% abv")) == nil)
        // A word the law does not define there is not enough on its own.
        #expect(certificate(wine("Cabernet", country: "United States", designation: "Reserve")) == nil)
    }

    @Test func CELLAR_R30_theColossal_isTopTwoPercent_byItsGrandeReserva() throws {
        let result = try #require(certificate(wine(classification: "Vinho Regional Lisboa · 14% abv",
                                                   designation: "Grande Reserva")))
        #expect(result.appellation == "Lisboa")
        #expect(result.category == "Vinho Regional")
        #expect(result.tier == .regional)
        #expect(result.designationStrength == .strong)
        #expect(result.designationNote?.contains("Portugal") == true)
        #expect(result.insight?.contains("regional wine") == true)
        #expect(result.topPercent == 2)
        #expect(result.basis == ["Grande Reserva"])
    }

    @Test func CELLAR_R30_aDOCG_alone_isTopTwenty_soTheCardLeadsWithItsLevel() throws {
        let result = try #require(certificate(wine("Chianti Classico", country: "Italy",
                                                   classification: "Chianti Classico DOCG")))
        #expect(result.tier == .top)
        #expect(result.topPercent == nil)
        #expect(result.printed == "Chianti Classico DOCG")
    }

    @Test func CELLAR_R30_DOCGRiservaAndGold_isTopOne() throws {
        let gold = WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)
        let result = try #require(certificate(wine("Chianti Classico", country: "Italy",
                                                   classification: "Chianti Classico DOCG", designation: "Riserva",
                                                   awards: [gold])))
        #expect(result.recognition == 3)
        #expect(result.topPercent == 1)
        #expect(result.basis == ["DOCG", "Riserva", gold.text])
    }

    @Test func CELLAR_R30_aPlainDOC_showsTheCard_withoutATop() throws {
        let result = try #require(certificate(wine(classification: "Douro DOC")))
        #expect(result.topPercent == nil)
        #expect(result.insight?.contains("protected origin") == true)
    }

    @Test func CELLAR_R30_theCatalogsLine_comesBeforeTheCategorys() throws {
        let result = try #require(certificate(wine(classification: "Douro DOC", insight: "Portugal's oldest region.")))
        #expect(result.insight == "Portugal's oldest region.")
    }

    @Test func CELLAR_R30_aKnownAppellationWithoutCategory_isProtected_andANotableOneIsTop() throws {
        #expect(certificate(wine(classification: "Colchagua Valley"))?.tier == nil)
        #expect(certificate(wine(classification: "Colchagua Valley", insight: "Chile's red heartland."))?.tier
            == .protected)
        let sauternes = try #require(certificate(wine(classification: "Sauternes AOC", insight: "Noble rot.",
                                                      notable: true)))
        #expect(sauternes.tier == .top)
    }

    @Test func CELLAR_R30_theTermInTheName_counts() throws {
        let result = try #require(certificate(wine("Colossal Reserva", classification: "Lisboa")))
        #expect(result.designation == "Reserva")
        #expect(result.designationStrength == .aged)
        #expect(result.topPercent == 7)
    }

    @Test func CELLAR_R30_recognition_byMedalAndCompetition() {
        #expect(Certification.level(WineAward(competition: "Decanter World Wine Awards", medal: .trophy)) == 4)
        #expect(Certification.level(WineAward(competition: "Mundus Vini", medal: .gold)) == 3)
        #expect(Certification.level(WineAward(competition: "Gilbert & Gaillard", medal: .gold)) == 2)
        #expect(Certification.level(WineAward(competition: "Feira da Vila", medal: .gold)) == 1)
        #expect(Certification.level(WineAward(competition: "James Suckling", points: 95)) == 4)
        #expect(Certification.level(WineAward(competition: "James Suckling", points: 92)) == 3)
        #expect(Certification.level(WineAward(competition: "Wine Spectator", points: 90)) == 2)
        #expect(Certification.level(WineAward(competition: "Someone", points: 99)) == 1)
    }

    @Test func CELLAR_R30_anAwardAlone_givesACard() throws {
        let bronze = WineAward(competition: "Feira da Vila", medal: .bronze)
        let result = try #require(certificate(wine(awards: [bronze])))
        #expect(result.topPercent == 10)
        #expect(result.awards == [bronze])
    }

    @Test func CELLAR_R30_cameraNoise_isNoAward_andRaisesNothing() throws {
        let noise = [WineAward(competition: "SENTENA COM.", medal: .trophy),
                     WineAward(competition: "POLON US II@", medal: .silver)]
        let result = try #require(certificate(wine(classification: "Vinho Regional Lisboa", designation: "Grande Reserva",
                                                   awards: noise)))
        #expect(result.awards.isEmpty)
        #expect(result.recognition == 0)
        #expect(result.basis == ["Grande Reserva"])
    }

    // MARK: A scanned appellation

    private func catalogWine(_ id: String, _ classification: String, insight: String) -> Wine {
        Wine(id: id, name: id, origin: "", classification: classification, profile: PalateMap([:]),
             appellationInsight: insight)
    }

    @Test func CELLAR_R30_aLabelThatSaysLisboa_isTheRegionalWineTheCatalogKnows() throws {
        let vocabulary = LabelVocabulary(wines: [
            catalogWine("a", "Vinho Regional Lisboa · 13% abv", insight: "Portugal's regional label."),
            catalogWine("b", "Vinho Regional Lisboa", insight: "Portugal's regional label.")
        ])
        let scanned = vocabulary.describingAppellation(of: wine(classification: "Lisboa · 14% abv",
                                                                designation: "Grande Reserva"))
        #expect(scanned.classification == "Vinho Regional Lisboa · 14% abv")
        let result = try #require(certificate(scanned))
        #expect(result.tier == .regional)
        #expect(result.insight == "Portugal's regional label.")
    }

    @Test func CELLAR_R30_aPlaceThatIsBothADOCAndARegionalWine_isLeftUnranked() {
        let vocabulary = LabelVocabulary(wines: [
            catalogWine("a", "DoTejo DOC", insight: "Portugal's protected origin label (DOC)."),
            catalogWine("b", "Tejo DOC", insight: "Portugal's protected origin label (DOC)."),
            catalogWine("c", "Vinho Regional Tejo", insight: "Portugal's regional label.")
        ])
        let scanned = vocabulary.describingAppellation(of: wine(classification: "Tejo"))
        #expect(scanned.classification == "Tejo")
        #expect(scanned.appellationInsight == nil)
        #expect(certificate(scanned) == nil)
    }

    @Test func CELLAR_R30_categoriesOfTheSameRank_keepTheCatalogsLine() throws {
        let vocabulary = LabelVocabulary(wines: [
            catalogWine("a", "Mosel Qualitätswein", insight: "Germany's quality wine."),
            catalogWine("b", "Mosel Prädikatswein", insight: "Germany's quality wine.")
        ])
        let scanned = vocabulary.describingAppellation(of: wine(classification: "Mosel"))
        #expect(scanned.classification == "Mosel")
        #expect(scanned.appellationInsight == "Germany's quality wine.")
        #expect(try #require(certificate(scanned)).tier == .protected)
    }

    // MARK: Top X%

    @Test func CELLAR_R30_top_isRoundedAsTheCardWritesIt() {
        #expect(QualityEstimate.rounded(0.4) == 1)
        #expect(QualityEstimate.rounded(7.3) == 7)
        #expect(QualityEstimate.rounded(10.4) == 10)
        #expect(QualityEstimate.rounded(23) == 25)
    }

    @Test func CELLAR_R30_top_onlyInTheTopTen() {
        #expect(QualityEstimate.topPercent(tier: .protected, strength: nil, recognition: 0, prevalence: prevalence)
            == nil)
        #expect(QualityEstimate.topPercent(tier: .top, strength: nil, recognition: 0, prevalence: prevalence) == nil)
        #expect(QualityEstimate.topPercent(tier: nil, strength: .aged, recognition: 0, prevalence: prevalence) == 7)
        #expect(QualityEstimate.topPercent(tier: nil, strength: nil, recognition: 0, prevalence: prevalence) == nil)
    }

    @Test func CELLAR_R30_thePrevalence_isPackedWithTheApp() {
        let packed = QualityPrevalence.packed
        #expect((0...1).contains(packed.appellation["top"] ?? -1))
        #expect((0...1).contains(packed.designation["strong"] ?? -1))
        #expect(packed.recognition["3"] == 0.02)
    }

    @Test func CELLAR_R30_theScannedColossal_withThePackedPrevalence_showsItsTop() throws {
        let colossal = Wine(id: "casa-santos-leia-colossal-2023", name: "COLOSSAL", producer: "CASA SANTOS LEIA",
                            vintage: 2023, origin: "Lisboa, Portugal", region: "Lisboa", country: "Portugal",
                            classification: "Lisboa · 14% abv", profile: PalateMap([:]),
                            appellationInsight: "Portugal's regional label.", designation: "Grande Reserva")
        let result = try #require(Certification.make(for: colossal))
        #expect(result.topPercent == 2)
    }
}
