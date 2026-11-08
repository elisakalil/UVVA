import Core
import Foundation
import Vision

/// Reads the text of the label photos on the phone with Vision (CELLAR-R17): no network, no cost.
struct VisionLabelReader: LabelReading {
    /// The languages of the labels UVVA expects, as Vision names them.
    static let languages = ["pt-PT", "pt-BR", "en-US", "fr-FR", "it-IT", "es-ES", "de-DE"]

    func read(front: Data, back: Data) async throws -> LabelText {
        async let frontLines = lines(in: front, side: .front)
        async let backLines = lines(in: back, side: .back)
        return LabelText(try await frontLines + backLines)
    }

    private func lines(in photo: Data, side: LabelSide) async throws -> [LabelLine] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = Set(request.supportedRecognitionLanguages.map(\.maximalIdentifier))
        request.recognitionLanguages = Self.languages
            .map { Locale.Language(identifier: $0) }
            .filter { supported.contains($0.maximalIdentifier) }
        let observations = try await request.perform(on: photo)
        return observations.compactMap { observation in
            guard let best = observation.topCandidates(1).first else { return nil }
            return LabelLine(best.string, side: side, height: Double(observation.boundingBox.height),
                             confidence: Double(best.confidence))
        }
    }
}
