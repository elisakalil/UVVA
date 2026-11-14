import CoreGraphics
import Testing
@testable import Core

/// The back label read frame after frame (CELLAR-R17): what several frames read alike is sure; what one frame made
/// up is not.
struct LabelScanTests {
    private func line(_ text: String, _ confidence: Double = 0.5) -> LabelLine {
        LabelLine(text, side: .back, confidence: confidence)
    }

    @Test func CELLAR_R17_aLineReadInSeveralFrames_isConfirmed_andNoiseIsDoubted() {
        var scan = LabelScan()
        scan.add([line("Castas: Touriga Nacional, Syrah"), line("Trophy SENTENA COM.")])
        scan.add([line("Castas: Touriga Nacional, Syrah"), line("POLON US II@")])
        scan.add([line("Castas: Touriga Nacionai, Syrah"), line("CANTA SYY")])
        #expect(scan.frames == 3)
        #expect(scan.confirmedCount == 1)
        let lines = scan.lines()
        #expect(lines.map(\.text) == ["Castas: Touriga Nacional, Syrah", "Trophy SENTENA COM.", "POLON US II@",
                                      "CANTA SYY"])
        // Three votes: at least 0.8, whatever each frame thought.
        #expect(abs(lines[0].confidence - 0.8) < 0.0001)
        // Read once in a scan: doubted, under what an award needs.
        #expect(abs(lines[1].confidence - 0.2) < 0.0001)
        #expect(lines.allSatisfy { $0.side == .back })
    }

    @Test func CELLAR_R17_aPhotoAlone_keepsTheRecognizersConfidence() {
        var scan = LabelScan()
        scan.add([line("Produzido e engarrafado por Casa Santos Lima", 0.9)])
        #expect(scan.confirmedCount == 0)
        #expect(scan.lines().first?.confidence == 0.9)
    }

    @Test func CELLAR_R17_twoLinesOfOneFrame_areNeverMerged() {
        var scan = LabelScan()
        for _ in 0..<3 { scan.add([line("13,5% vol"), line("12,5% vol")]) }
        #expect(scan.lines().map(\.text) == ["13,5% vol", "12,5% vol"])
        #expect(scan.confirmedCount == 2)
    }

    @Test func CELLAR_R17_aLineFirstReadLater_comesAfter() {
        var scan = LabelScan()
        scan.add([line("COLOSSAL")])
        scan.add([line("COLOSSAL"), line("Vinho Regional Lisboa")])
        scan.add([line("Vinho Regional Lisboa")])
        #expect(scan.lines().map(\.text) == ["COLOSSAL", "Vinho Regional Lisboa"])
    }

    @Test func CELLAR_R17_piecesOfALine_cutByTheCurve_areLaidOnOneAnother() {
        var scan = LabelScan()
        scan.add([line("Após uma criteriosa seleção das mel")])
        scan.add([line("ós uma criteriosa seleção das melhores uvas,")])
        scan.add([line("criteriosa seleção das melhores uvas, este vinho")])
        scan.add([line("seleção das melhores uvas, este vinho")])
        #expect(scan.lines().map(\.text) == ["Após uma criteriosa seleção das melhores uvas, este vinho"])
        #expect(scan.confirmedCount == 1)
    }

    @Test func CELLAR_R17_twoLinesSharingAWordOrTwo_stayApart() {
        var scan = LabelScan()
        for _ in 0..<3 {
            scan.add([line("aromas vincados de fruta vermelha e preta"),
                      line("de especiarias doces e cacau. O estágio parcial")])
        }
        #expect(scan.lines().count == 2)
    }

    @Test func CELLAR_R17_aBlurredFrame_isLeftOut() {
        var scan = LabelScan()
        let blurred = scan.addFrame([line("dick ngo fruit", 0.3), line("gicy and cora", 0.3), line("Basal", 0.3)])
        let sharp = scan.addFrame([line("COLOSSAL", 1), line("TINTO - RED", 1), line("Basal", 0.3)])
        #expect(!blurred)
        #expect(sharp)
        #expect(scan.frames == 1)
        #expect(scan.skippedFrames == 1)
        #expect(scan.readings.count == 1)
    }

    @Test func CELLAR_R17_sameLine_allowsAFewWrongLetters_only() {
        #expect(LabelScan.isSameLine("touriga nacional syrah", "touriga nacionai syrah"))
        #expect(!LabelScan.isSameLine("vinho regional lisboa", "vinho regional tejo"))
        #expect(!LabelScan.isSameLine("2023", "2022"))
    }

    @Test func CELLAR_R30_aScannedSticker_backsTheModelsAward() {
        var scan = LabelScan()
        for _ in 0..<3 {
            scan.add([line("CONCURSO VINHOS DE PORTUGAL", 0.3), line("MEDALHA DE OURO", 0.3)])
        }
        let gold = WineAward(competition: "Concurso Vinhos de Portugal", medal: .gold)
        #expect(AwardEvidence.isRead(gold, in: scan.lines()))
    }
}

/// The part of a video frame the scan reads: the label frame on screen (CELLAR-R17).
struct LabelScanRegionTests {
    @Test func CELLAR_R17_theFrameOnScreen_isTheSameShareOfTheVideo() throws {
        // A 3:4 video filling a 402×874 screen is cropped at the sides: it shows 655.5 points wide.
        let region = try #require(LabelScanRegion.normalized(
            label: CGRect(x: 40, y: 200, width: 322, height: 447), preview: CGRect(x: 0, y: 0, width: 402, height: 874),
            frame: CGSize(width: 3024, height: 4032)))
        let shown = 874.0 * 3024 / 4032
        let width = 322 / shown * 1.12
        #expect(abs(region.width - width) < 0.001)
        #expect(abs(region.midX - 0.5) < 0.001)
        // Vision counts from the bottom: the frame's middle is 423.5 points from the top.
        #expect(abs(region.midY - (1 - 423.5 / 874)) < 0.001)
    }

    @Test func CELLAR_R17_noFrame_noRegion() {
        #expect(LabelScanRegion.normalized(label: .zero, preview: CGRect(x: 0, y: 0, width: 1, height: 1),
                                           frame: CGSize(width: 1, height: 1)) == nil)
    }
}

/// A reading exported from a debug build and replayed (CELLAR-R17).
struct LabelScanExportTests {
    @Test func CELLAR_R17_anExportedScan_readsBackTheSame() throws {
        let frame = [LabelLine("VINHO REGIONAL LISBOA", side: .back, confidence: 1)]
        let export = LabelScanExport(front: [LabelLine("COLOSSAL", height: 0.1)],
                                     backPhoto: frame, frames: [frame, frame])
        let replayed = try LabelScanExport(json: export.json)
        #expect(replayed == export)
        #expect(replayed.text.back.map(\.text) == ["VINHO REGIONAL LISBOA"])
        #expect(replayed.text.back.first?.confidence ?? 0 >= 0.8)
    }
}
