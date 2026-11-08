import Core
import Foundation
import FoundationModels

/// Sorts the label's text into the wine's facts with the model on the phone, when there is one (iOS 26 with
/// Apple Intelligence). Elsewhere it gives nothing and the parser does the work alone (CELLAR-R17).
struct DeviceLabelStructurer: LabelStructuring {
    func structure(_ text: LabelText) async -> LabelFacts? {
        if #available(iOS 26.0, *) {
            return await FoundationLabelStructurer().structure(text)
        }
        return nil
    }
}

@available(iOS 26.0, *)
private struct FoundationLabelStructurer {
    @Generable
    struct Label {
        @Guide(description: "The wine's own name, without the producer, the vintage or the appellation")
        var name: String?
        @Guide(description: "The winery or producer, such as a Quinta, Château, Domaine, Bodega or Weingut")
        var producer: String?
        @Guide(description: "The vintage year, only if printed as the harvest year; never a founding date")
        var vintage: Int?
        @Guide(description: "One of: Red, White, Rosé, Sparkling, Fortified")
        var type: String?
        @Guide(description: "The appellation or region, as printed")
        var region: String?
        @Guide(description: "The country, in English")
        var country: String?
        @Guide(description: "The grape varieties, as printed")
        var grapes: [String]
        @Guide(description: "The alcohol by volume, as a number such as 13.5")
        var alcohol: Double?
    }

    static let instructions = """
        You read the text found on the front and back labels of a wine bottle and fill in the wine's facts. \
        Use only what the text says. Leave a field empty when the label does not show it.
        """

    func structure(_ text: LabelText) async -> LabelFacts? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let prompt = """
            Front label:
            \(text.front.map(\.text).joined(separator: "\n"))

            Back label:
            \(text.back.map(\.text).joined(separator: "\n"))
            """
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let label = try await session.respond(to: prompt, generating: Label.self).content
            let types = ["Red", "White", "Rosé", "Sparkling", "Fortified"]
            return LabelFacts(name: label.name.nonEmpty, producer: label.producer.nonEmpty, vintage: label.vintage,
                              type: types.first { $0.caseInsensitiveCompare(label.type ?? "") == .orderedSame },
                              region: label.region.nonEmpty, country: label.country.nonEmpty,
                              grapes: label.grapes.compactMap(\.nonEmpty),
                              alcohol: label.alcohol.flatMap { (5...23).contains($0) ? $0 : nil })
        } catch {
            return nil
        }
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? { self?.nonEmpty }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
