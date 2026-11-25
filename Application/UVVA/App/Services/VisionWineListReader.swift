import Core
import Foundation
import Vision

/// Reads the text of a photo of a wine list on the phone with Vision (WINELIST-R03): no network, no cost. Each run of
/// text keeps where it sits on the page, so the parser can put a wine's name and its price back on one row.
struct VisionWineListReader: WineListReading {
    func read(_ photo: Data) async throws -> [WineListLine] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = Set(request.supportedRecognitionLanguages.map(\.maximalIdentifier))
        request.recognitionLanguages = VisionLabelReader.languages
            .map { Locale.Language(identifier: $0) }
            .filter { supported.contains($0.maximalIdentifier) }
        let observations = try await request.perform(on: photo)
        return observations.compactMap { observation in
            guard let best = observation.topCandidates(1).first else { return nil }
            // Vision measures from the bottom left; the page is read from the top.
            let box = observation.boundingBox.cgRect
            return WineListLine(best.string, minX: Double(box.minX), minY: Double(1 - box.maxY),
                                width: Double(box.width), height: Double(box.height),
                                confidence: Double(best.confidence))
        }
    }
}
