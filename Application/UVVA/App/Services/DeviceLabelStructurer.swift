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
        @Guide(description: "The wine region, as printed, such as Douro, Lisboa or Rioja")
        var region: String?
        @Guide(description: "The official origin mention with its category, as printed and with spelling fixed, such as Douro DOC, Chianti Classico DOCG, Vinho Regional Lisboa, Rioja DOCa or Appellation Margaux Contrôlée")
        var appellation: String?
        @Guide(description: "A legal ageing or rank term printed on the label: Reserva, Grande Reserva, Gran Reserva, Riserva or Crianza. Never part of the wine's name")
        var designation: String?
        @Guide(description: "The medals, trophies and critics' scores printed or stuck on the bottle; only what the text shows")
        var awards: [Award]
        @Guide(description: "The country, in English")
        var country: String?
        @Guide(description: "The grape varieties, as printed")
        var grapes: [String]
        @Guide(description: "The alcohol by volume, as a number such as 13.5")
        var alcohol: Double?
        @Guide(description: "The aromas and flavours the label describes, each the name of a thing that smells or tastes, in English, such as plum, black pepper, red fruit or cocoa. Never a colour, an adjective or a word about the wine's structure alone, such as red, black, ripe, balanced or complex")
        var notes: [String]
        @Guide(description: "The foods the label suggests the wine with, each a short phrase in English, such as grilled lamb")
        var pairings: [String]
        @Guide(description: "The lowest serving temperature in degrees Celsius, only if the label gives one")
        var servingFrom: Int?
        @Guide(description: "The highest serving temperature in degrees Celsius, only if the label gives one")
        var servingTo: Int?
    }

    @Generable
    struct Award {
        @Guide(description: "The competition or the critic, such as Decanter World Wine Awards, Concours Mondial de Bruxelles or James Suckling")
        var source: String
        @Guide(description: "For a medal, one of: Trophy, Platinum, Double Gold, Gold, Silver, Bronze, Commended")
        var medal: String?
        @Guide(description: "For a critic's score, the points out of 100")
        var points: Int?
        @Guide(description: "The year of the award, if printed")
        var year: Int?
    }

    static let instructions = """
        You read the text found on the front and back labels of a wine bottle and fill in the wine's facts. \
        The text comes from a camera: words may be split across lines, misspelt or in another language. \
        The back label often describes the aromas, the foods to pair and how cold to serve the wine. \
        Medals and seals are often round stickers on the front, their words split over several lines. \
        Use only what the text says. Leave a field empty when the label does not show it.
        """

    /// A label is text the user brings for the model to sort, not a request: the guardrails meant for that, so a
    /// label's alcohol and health warnings are not taken for unsafe content.
    private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

    func structure(_ text: LabelText) async -> LabelStructuringResult {
        let context = FoundationModelSupport.context(model)
        if case let .unavailable(reason) = model.availability {
            return LabelStructuringResult(failure: FoundationModelSupport.describe(reason), context: context)
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
                              appellation: label.appellation.nonEmpty,
                              region: label.region.nonEmpty, country: label.country.nonEmpty,
                              grapes: label.grapes.compactMap(\.nonEmpty),
                              alcohol: label.alcohol.flatMap { (5...23).contains($0) ? $0 : nil },
                              notes: label.notes.compactMap(\.nonEmpty).map(\.capitalizedFirst),
                              pairings: label.pairings.compactMap(\.nonEmpty).map(\.capitalizedFirst),
                              serving: Self.serving(from: label.servingFrom, to: label.servingTo),
                              // Only a term the law knows: "Reserva" in a name is not one.
                              designation: label.designation.flatMap(CertificationKeywords.designation(in:)),
                              // Only what the camera surely read: the model may not make a medal out of noise.
                              awards: label.awards.compactMap(Self.award)
                                  .filter { AwardEvidence.isRead($0, in: text.lines) })
            return LabelStructuringResult(facts: facts, context: context)
        } catch let error as LanguageModelSession.GenerationError {
            return LabelStructuringResult(failure: FoundationModelSupport.describe(error), context: context)
        } catch {
            return LabelStructuringResult(failure: "The model failed: \(error.localizedDescription)", context: context)
        }
    }

    /// A medal or a score from the label, with the competition spelt as UVVA knows it; nothing without a medal or a
    /// plausible score.
    private static func award(_ award: Award) -> WineAward? {
        guard let source = award.source.nonEmpty else { return nil }
        let name = CertificationKeywords.source(in: source)?.name ?? source
        let year = award.year.flatMap { (1990...2100).contains($0) ? $0 : nil }
        if let medal = award.medal.flatMap(WineAward.Medal.init(title:)) {
            return WineAward(competition: name, medal: medal, year: year)
        }
        if let points = award.points, (80...100).contains(points) {
            return WineAward(competition: name, points: points, year: year)
        }
        return nil
    }

    /// A temperature a wine is served at, 4 to 22 °C; one end alone is a range of one degree.
    private static func serving(from low: Int?, to high: Int?) -> ClosedRange<Int>? {
        let plausible = 4...22
        let ends = [low, high].compactMap { $0 }.filter(plausible.contains)
        guard let lowest = ends.min(), let highest = ends.max() else { return nil }
        return lowest...highest
    }
}
