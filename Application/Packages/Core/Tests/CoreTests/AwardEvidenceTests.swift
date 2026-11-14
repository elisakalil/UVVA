import Testing
@testable import Core

/// When an award read off a label is worth showing (CELLAR-R30): the catalog has none, so a competition UVVA does not
/// know still counts, but camera noise never does.
struct AwardEvidenceTests {
    @Test(arguments: [
        "Decanter World Wine Awards", "Concurso Vinhos de Portugal", "Concurso Nacional de Vinhos Engarrafados",
        "Feira da Vila", "Vinalies Internationales", "Sélections Mondiales des Vins", "Mundus Vini"
    ])
    func CELLAR_R30_aCompetition_knownOrNot_isPlausible(name: String) {
        #expect(WineAward(competition: name, medal: .gold).isPlausible)
    }

    @Test(arguments: ["SENTENA COM.", "POLON US II@", "CANTA SYY", "ZZ", "Lisboa"])
    func CELLAR_R30_cameraNoise_isNoCompetition(name: String) {
        #expect(!WineAward(competition: name, medal: .trophy).isPlausible)
    }

    @Test func CELLAR_R30_noiseStoredByAnOlderReading_isDroppedOnTheWayBack() {
        #expect(WineAward(text: "Trophy · SENTENA COM.") == nil)
        #expect(WineAward(text: "Silver · POLON US II@") == nil)
        #expect(WineAward(text: "Gold · Concurso Vinhos de Portugal · 2024") != nil)
    }

    private let sticker = [
        LabelLine("CONCURSO NACIONAL", confidence: 0.9),
        LabelLine("DE VINHOS ENGARRAFADOS", confidence: 0.8),
        LabelLine("MEDALHA DE OURO 2024", confidence: 0.9)
    ]

    @Test func CELLAR_R30_theModelsAward_counts_whenTheCameraReadIt() {
        let gold = WineAward(competition: "Concurso Nacional de Vinhos Engarrafados", medal: .gold, year: 2024)
        #expect(AwardEvidence.isRead(gold, in: sticker))
    }

    @Test func CELLAR_R30_theModelsAward_needsTheMedalItClaims() {
        let silver = WineAward(competition: "Concurso Nacional de Vinhos Engarrafados", medal: .silver)
        #expect(!AwardEvidence.isRead(silver, in: sticker))
    }

    @Test func CELLAR_R30_theModelsAward_isNotRead_offLinesTheCameraWasUnsureOf() {
        let blurred = sticker.map { LabelLine($0.text, confidence: 0.3) }
        let gold = WineAward(competition: "Concurso Nacional de Vinhos Engarrafados", medal: .gold)
        #expect(!AwardEvidence.isRead(gold, in: blurred))
    }

    @Test func CELLAR_R30_theModelsAward_cannotNameACompetitionTheLabelDoesNot() {
        let invented = WineAward(competition: "Decanter World Wine Awards", medal: .gold)
        #expect(!AwardEvidence.isRead(invented, in: sticker))
        let noise = [LabelLine("Trophy SENTENA COM.", confidence: 0.9)]
        #expect(!AwardEvidence.isRead(WineAward(competition: "SENTENA COM.", medal: .trophy), in: noise))
    }

    @Test func CELLAR_R30_aCriticsScore_needsItsNumberOnTheLabel() {
        let lines = [LabelLine("JAMES SUCKLING 93 POINTS", confidence: 0.9)]
        #expect(AwardEvidence.isRead(WineAward(competition: "James Suckling", points: 93), in: lines))
        #expect(!AwardEvidence.isRead(WineAward(competition: "James Suckling", points: 95), in: lines))
    }
}
