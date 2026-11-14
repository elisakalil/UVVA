import Core
import Foundation
import FoundationModels

/// Adds dishes to a wine's pairings with the model on the phone, when there is one (iOS 26 with Apple Intelligence),
/// from everything known of the wine and the pairings it already has (CELLAR-R17). Elsewhere it adds nothing.
struct DevicePairingSuggester: PairingSuggesting {
    func suggestPairings(for wine: Wine) async -> PairingSuggestionResult {
        if #available(iOS 26.0, *) {
            return await FoundationPairingSuggester().suggest(for: wine)
        }
        return PairingSuggestionResult(failure: "Needs iOS 26; this phone runs iOS \(DeviceLabelStructurer.systemVersion).")
    }
}

@available(iOS 26.0, *)
private struct FoundationPairingSuggester {
    @Generable
    struct Suggestion {
        @Guide(description: "Three dishes that pair well with this wine and are not in the list of pairings already given, each a short, specific dish in English, such as grilled lamb chops", .count(3))
        var dishes: [String]
    }

    static let instructions = """
        You are a sommelier. Given a wine, you suggest dishes to eat with it. \
        Match the weight of the dish to the body of the wine. Tannin wants protein and fat, such as red meat or hard cheese. \
        High acidity suits acidic, fatty or fried dishes. The wine must be at least as sweet as the dish. \
        Avoid hot, spicy dishes with high alcohol or high tannin. Prefer the classic dishes of the wine's region. \
        Name concrete dishes, never a broad category such as meat or fish, and never a drink.
        """

    private let model = SystemLanguageModel.default

    func suggest(for wine: Wine) async -> PairingSuggestionResult {
        if case let .unavailable(reason) = model.availability {
            return PairingSuggestionResult(failure: FoundationModelSupport.describe(reason))
        }
        do {
            let session = LanguageModelSession(model: model, instructions: Self.instructions)
            let suggestion = try await session.respond(to: Self.prompt(for: wine), generating: Suggestion.self).content
            let known = Set(wine.pairings.map { $0.lowercased() })
            let dishes = [String]().adding(suggestion.dishes.compactMap(\.nonEmpty).map(\.capitalizedFirst))
                .filter { !known.contains($0.lowercased()) }
            return PairingSuggestionResult(pairings: dishes, failure: dishes.isEmpty ? "The model gave no new dish." : nil)
        } catch let error as LanguageModelSession.GenerationError {
            return PairingSuggestionResult(failure: FoundationModelSupport.describe(error))
        } catch {
            return PairingSuggestionResult(failure: "The model failed: \(error.localizedDescription)")
        }
    }

    /// Everything known of the wine, one fact a line, and the pairings it already has.
    static func prompt(for wine: Wine) -> String {
        let year = Calendar(identifier: .gregorian).component(.year, from: .now)
        let place = [wine.appellation, wine.region, wine.country].compactMap(\.nonEmpty)
            .reduce(into: [String]()) { places, place in if !places.contains(place) { places.append(place) } }
        let rows: [(String, String?)] = [
            ("Wine", [wine.name, wine.producer].compactMap(\.nonEmpty).joined(separator: ", ").nonEmpty),
            ("Type", wine.type.nonEmpty),
            ("Vintage", wine.vintage.map { "\($0) (\(max(0, year - $0)) years old)" }),
            ("Grapes", wine.grapes.isEmpty ? nil : wine.grapes.joined(separator: ", ")),
            ("Origin", place.isEmpty ? nil : place.joined(separator: ", ")),
            ("Alcohol", wine.alcohol.map { "\($0)%" }),
            ("Aromas and flavours", wine.noteItems.isEmpty ? nil : wine.noteItems.joined(separator: ", ")),
            ("Structure (0 to 9)", structure(wine.profile))
        ]
        let facts = rows.compactMap { label, value in value.map { "\(label): \($0)" } }.joined(separator: "\n")
        let given = wine.pairings.isEmpty ? "none" : wine.pairings.joined(separator: ", ")
        return """
            \(facts)
            Pairings already given: \(given)

            Suggest three more dishes for this wine.
            """
    }

    /// "body 7 (high), tannin 6 (high), acidity 5 (medium)…"; nothing for a wine with no map.
    private static func structure(_ profile: PalateMap) -> String? {
        guard PalateAxis.allCases.contains(where: { profile[$0] > 0 }) else { return nil }
        let axes: [PalateAxis] = [.body, .tannin, .acidity, .sweetness, .oak, .fruit, .spice, .floral]
        return axes.map { axis in
            let value = profile[axis]
            let level = value < 3.5 ? "low" : value < 6 ? "medium" : "high"
            return "\(axis.rawValue) \(value.formatted(.number.precision(.fractionLength(0...1)))) (\(level))"
        }.joined(separator: ", ")
    }
}
