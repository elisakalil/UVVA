import Testing
@testable import Core

/// What is left of a label's text for the parser and the model, and what a reading may add to a wine (CELLAR-R17).
/// The lines are the Colossal's back label as a scan read it.
struct LabelCleaningTests {
    private func back(_ text: String, _ confidence: Double = 1) -> LabelLine {
        LabelLine(text, side: .back, confidence: confidence)
    }

    @Test(arguments: [
        "Contains Sulphites / Contient des Sulfites / Enthält Sulfite", "Can alton /Contains Sulphies / Contient des",
        "Nutritional Declaration and Ingredients", "Beclaration No", "E/100ml = 344 kJ/82 kcal", "8/100ml - 34 k/8 cal",
        "SYY 7481694", "604422", "JA", "• ne", "64"
    ])
    func CELLAR_R17_whatSaysNothingOfTheWine_isLeftOut(line: String) {
        #expect(LabelTextCleaner.isBoilerplate(line))
    }

    @Test(arguments: [
        "VINHO REGIONAL LISBOA", "GRANDE RESERVA. 2023", "750 ml alc. 14% vol.", "TINTO - RED", "2023",
        "Com final muito persistente e elegante este é um vinho para apreciar em momentos especiais.",
        "and with great structure this Grande Reserva shows", "Casa Santos Lima"
    ])
    func CELLAR_R17_whatIsAboutTheWine_stays(line: String) {
        #expect(!LabelTextCleaner.isBoilerplate(line))
    }

    @Test func CELLAR_R17_aLineAnotherAlreadySays_goes_andLendsItsConfidence() {
        let text = LabelTextCleaner.clean(LabelText([
            back("emerges the spicy and cocoa aromas", 1),
            back("On the palate emerges the spicy and cocoa aromas. The partial ageing in oak", 0.4),
            back("SYY 7481694")
        ]))
        #expect(text.back.map(\.text) == ["On the palate emerges the spicy and cocoa aromas. The partial ageing in oak"])
        #expect(text.back.first?.confidence == 1)
    }

    @Test func CELLAR_R17_theModelGetsTheSurestBackLines_inTheLabelsOrder() {
        let text = LabelText([LabelLine("COLOSSAL"), back(String(repeating: "a", count: 50), 0.4),
                              back(String(repeating: "b", count: 50), 1), back(String(repeating: "c", count: 50), 0.8)])
        let forModel = LabelTextCleaner.forModel(text, backCharacters: 110)
        #expect(forModel.front.map(\.text) == ["COLOSSAL"])
        #expect(forModel.back.map { $0.text.first } == ["b", "c"])
    }

    // MARK: Notes and producer

    private let vocabulary = LabelVocabulary(wines: [
        Wine(id: "csl-red", name: "Red Blend", producer: "Casa Santos Lima", origin: "Lisboa, Portugal",
             profile: PalateMap([:]), note: "Plum, black cherry, spice."),
        Wine(id: "other", name: "Other", producer: "Quinta do Crasto", origin: "Douro, Portugal",
             profile: PalateMap([:]))
    ])

    @Test func CELLAR_R17_onlyAromasAreNotes() {
        #expect(vocabulary.aromas(in: ["Spicy", "Cocoa", "Firate", "Pe", "Eaten", "Black cherries", "plum", "Plum"])
            == ["Spice", "Cocoa", "Black cherry", "Plum"])
    }

    @Test func CELLAR_R17_aColourAlone_isNoAroma_evenWhenAScannedWineStoredIt() {
        let poisoned = LabelVocabulary(wines: [
            Wine(id: "scanned", name: "COLOSSAL", origin: "Lisboa, Portugal", profile: PalateMap([:]),
                 note: "Red, Black, Firate")
        ])
        #expect(poisoned.aromas(in: ["Red", "Black", "Firate", "Ripe red fruit", "Cocoa"]) == ["Red fruit", "Cocoa"])
    }

    @Test func CELLAR_R17_aProducerALetterOff_isTheCatalogs() {
        #expect(vocabulary.knownProducer("CASA SANTOS LEIA") == "Casa Santos Lima")
        #expect(vocabulary.knownProducer("CASA SANTOS LIMA") == "Casa Santos Lima")
        #expect(vocabulary.knownProducer("Herdade do Esporão") == nil)
    }

    @Test func CELLAR_R17_aWineScannedBefore_losesItsNoise() {
        let stored = Wine(id: "casa-santos-leia-colossal-2023", name: "COLOSSAL", producer: "CASA SANTOS LEIA",
                          origin: "Lisboa, Portugal", profile: PalateMap([:]),
                          note: "Fir tree, Ripe, Firate, Pe, Cocoa, Eaten, Spice")
        let cleaned = vocabulary.cleaning(stored)
        #expect(cleaned.producer == "Casa Santos Lima")
        #expect(cleaned.note == "Fir, Cocoa, Spice")
        #expect(cleaned.id == stored.id)
    }

    // MARK: Serving

    @Test func CELLAR_R17_aServingTemperature_mustBePrinted() {
        let printed = [back("Servir a 16-18 ºC"), back("Sangiovese")]
        #expect(ServingEvidence.isRead(16...18, in: printed))
        #expect(!ServingEvidence.isRead(10...12, in: printed))
        // Numbers on a line that is not about temperature are no serving temperature.
        #expect(!ServingEvidence.isRead(10...12, in: [back("10 12 rue de la Paix")]))
    }
}
