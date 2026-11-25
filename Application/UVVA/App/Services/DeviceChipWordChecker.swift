import Core
import Foundation
import FoundationModels
import OSLog

/// Asks the model on the phone, when there is one (iOS 26 with Apple Intelligence), whether a word typed in a chip
/// sheet is a real grape, aroma, dish, wine region or appellation (CELLAR-R18a). Elsewhere it cannot tell, and only
/// UVVA's lists decide.
struct DeviceChipWordChecker: ChipWordChecking {
    func check(_ word: String, as kind: ChipWordKind) async -> ChipWordVerdict {
        if #available(iOS 26.0, *) {
            return await FoundationChipWordChecker().check(word, as: kind)
        }
        return .unavailable(reason: "Needs iOS 26; this phone runs iOS \(DeviceLabelStructurer.systemVersion).")
    }
}

@available(iOS 26.0, *)
private struct FoundationChipWordChecker {
    @Generable
    struct Answer {
        @Guide(description: "True only when the word is certainly a real one of what is asked; false when it is made up, misspelt beyond recognition, something else, or when unsure")
        var isReal: Bool
    }

    static let instructions = """
        You are a sommelier who checks words typed into a wine app. The word may be in English, Portuguese or any \
        other language. Answer true only for a real, existing name of what is asked. Answer false for made-up words, \
        brands, people, jokes, and anything you are not sure of.
        """

    private let model = SystemLanguageModel.default
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    func check(_ word: String, as kind: ChipWordKind) async -> ChipWordVerdict {
        if case let .unavailable(reason) = model.availability {
            return verdict(.unavailable(reason: FoundationModelSupport.describe(reason)))
        }
        do {
            let session = LanguageModelSession(model: model, instructions: Self.instructions)
            let answer = try await session.respond(to: Self.question(word, kind), generating: Answer.self).content
            return answer.isReal ? .valid : .invalid
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // A word the safety filter stops is no grape, dish or place.
            return .invalid
        } catch let error as LanguageModelSession.GenerationError {
            let reason = FoundationModelSupport.describe(error)
            switch error {
            // The model is not on this iPhone yet, or not in its language: as good as off.
            case .assetsUnavailable, .unsupportedLanguageOrLocale:
                return verdict(.unavailable(reason: reason))
            default:
                return verdict(.failed(reason: reason))
            }
        } catch {
            return verdict(.failed(reason: "The model failed: \(error.localizedDescription)"))
        }
    }

    /// A verdict with no answer, logged with what decides whether the model runs ("iOS 26.1 · pt-PT · language
    /// supported").
    private func verdict(_ verdict: ChipWordVerdict) -> ChipWordVerdict {
        let context = FoundationModelSupport.context(model)
        switch verdict {
        case let .unavailable(reason):
            logger.error("Chip word not checked, no model: \(reason, privacy: .public) (\(context, privacy: .public))")
            return .unavailable(reason: "\(reason) (\(context))")
        case let .failed(reason):
            logger.error("Chip word not checked, model failed: \(reason, privacy: .public) (\(context, privacy: .public))")
            return .failed(reason: "\(reason) (\(context))")
        case .valid, .invalid:
            return verdict
        }
    }

    static func question(_ word: String, _ kind: ChipWordKind) -> String {
        let quoted = "“\(word)”"
        return switch kind {
        case .grape:
            "Is \(quoted) the name of a grape variety used to make wine?"
        case .aroma:
            "Is \(quoted) an aroma or flavour a wine can have, such as a fruit, flower, spice, herb, wood, earth or other smell or taste?"
        case .pairing:
            "Is \(quoted) a real food or dish that someone could eat with a glass of wine?"
        case .region:
            "Is \(quoted) a real wine region, or a real place where wine is made?"
        case .appellation:
            "Is \(quoted) a real wine appellation or protected designation of origin, such as Douro DOC, Rioja DOCa or Napa Valley AVA?"
        }
    }
}
