import Core
import Foundation
import FoundationModels

/// Sorts the label's text into the wine's facts with the model on the phone, when there is one (iOS 26 with
/// Apple Intelligence). Elsewhere it gives nothing and the parser does the work alone (CELLAR-R17).
struct DeviceLabelStructurer: LabelStructuring {
    /// "26.1", readable off the main thread.
    static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)" + (version.patchVersion > 0 ? ".\(version.patchVersion)" : "")
    }

    func structure(_ text: LabelText) async -> LabelStructuringResult {
        if #available(iOS 26.0, *) {
            return await FoundationLabelStructurer().structure(text)
        }
        return LabelStructuringResult(failure: "Needs iOS 26; this phone runs iOS \(Self.systemVersion).")
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
        @Guide(description: "The aromas and flavours the label describes, each a short word or two in English, such as plum or black pepper")
        var notes: [String]
        @Guide(description: "The foods the label suggests the wine with, each a short phrase in English, such as grilled lamb")
        var pairings: [String]
        @Guide(description: "The lowest serving temperature in degrees Celsius, only if the label gives one")
        var servingFrom: Int?
        @Guide(description: "The highest serving temperature in degrees Celsius, only if the label gives one")
        var servingTo: Int?
    }

    static let instructions = """
        You read the text found on the front and back labels of a wine bottle and fill in the wine's facts. \
        The text comes from a camera: words may be split across lines, misspelt or in another language. \
        The back label often describes the aromas, the foods to pair and how cold to serve the wine. \
        Use only what the text says. Leave a field empty when the label does not show it.
        """

    /// A label is text the user brings for the model to sort, not a request: the guardrails meant for that, so a
    /// label's alcohol and health warnings are not taken for unsafe content.
    private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

    func structure(_ text: LabelText) async -> LabelStructuringResult {
        let context = Self.context(model)
        if case let .unavailable(reason) = model.availability {
            return LabelStructuringResult(failure: Self.describe(reason), context: context)
        }
        let prompt = """
            Front label:
            \(text.front.map(\.text).joined(separator: "\n"))

            Back label:
            \(text.back.map(\.text).joined(separator: "\n"))
            """
        do {
            let session = LanguageModelSession(model: model, instructions: Self.instructions)
            let label = try await session.respond(to: prompt, generating: Label.self).content
            let types = ["Red", "White", "Rosé", "Sparkling", "Fortified"]
            let facts = LabelFacts(name: label.name.nonEmpty, producer: label.producer.nonEmpty, vintage: label.vintage,
                              type: types.first { $0.caseInsensitiveCompare(label.type ?? "") == .orderedSame },
                              region: label.region.nonEmpty, country: label.country.nonEmpty,
                              grapes: label.grapes.compactMap(\.nonEmpty),
                              alcohol: label.alcohol.flatMap { (5...23).contains($0) ? $0 : nil },
                              notes: label.notes.compactMap(\.nonEmpty).map(\.capitalizedFirst),
                              pairings: label.pairings.compactMap(\.nonEmpty).map(\.capitalizedFirst),
                              serving: Self.serving(from: label.servingFrom, to: label.servingTo))
            return LabelStructuringResult(facts: facts, context: context)
        } catch let error as LanguageModelSession.GenerationError {
            return LabelStructuringResult(failure: Self.describe(error), context: context)
        } catch {
            return LabelStructuringResult(failure: "The model failed: \(error.localizedDescription)", context: context)
        }
    }

    /// "iOS 26.1 · pt-PT · language supported": what decides whether the model runs.
    private static func context(_ model: SystemLanguageModel) -> String {
        let language = Locale.current.identifier
        let supported = model.supportsLocale(Locale.current) ? "language supported" : "language NOT supported by the model"
        return "iOS \(DeviceLabelStructurer.systemVersion) · \(language) · \(supported)"
    }

    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            "This device can't run Apple Intelligence (deviceNotEligible)."
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence is off in Settings, or the iPhone or Siri language is one it doesn't support (appleIntelligenceNotEnabled)."
        case .modelNotReady:
            // Apple's words for this reason: "downloading or because of other system reasons". It does not say which.
            "iOS says its model isn't ready (modelNotReady). It may still be downloading, or iOS may not be offering Apple Intelligence on this iPhone; iOS doesn't say which."
        @unknown default:
            "Unavailable: \(reason)."
        }
    }

    private static func describe(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .guardrailViolation:
            "Blocked by the model's safety filter (guardrailViolation)."
        case .unsupportedLanguageOrLocale:
            "The model doesn't support this language (unsupportedLanguageOrLocale)."
        case .exceededContextWindowSize:
            "The label text was too long for the model (exceededContextWindowSize)."
        case .assetsUnavailable:
            "The model's files aren't on the iPhone yet (assetsUnavailable)."
        case .rateLimited:
            "The system is limiting the model right now; try again (rateLimited)."
        case .refusal:
            "The model refused to answer (refusal)."
        default:
            "The model failed: \(error)"
        }
    }

    /// A temperature a wine is served at, 4 to 22 °C; one end alone is a range of one degree.
    private static func serving(from low: Int?, to high: Int?) -> ClosedRange<Int>? {
        let plausible = 4...22
        let ends = [low, high].compactMap { $0 }.filter(plausible.contains)
        guard let lowest = ends.min(), let highest = ends.max() else { return nil }
        return lowest...highest
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? { self?.nonEmpty }
}

private extension String {
    /// "plum" → "Plum", as the chips of the note are written.
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }

    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
