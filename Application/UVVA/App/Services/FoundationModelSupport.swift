import Foundation
import FoundationModels

/// What the readers of the model on the phone share: why it did not answer, in plain words for the debug section of
/// the note, and the phone as the model saw it.
@available(iOS 26.0, *)
enum FoundationModelSupport {
    /// "iOS 26.1 · pt-PT · language supported": what decides whether the model runs.
    static func context(_ model: SystemLanguageModel) -> String {
        let language = Locale.current.identifier
        let supported = model.supportsLocale(Locale.current) ? "language supported" : "language NOT supported by the model"
        return "iOS \(DeviceLabelStructurer.systemVersion) · \(language) · \(supported)"
    }

    static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
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

    static func describe(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .guardrailViolation:
            "Blocked by the model's safety filter (guardrailViolation)."
        case .unsupportedLanguageOrLocale:
            "The model doesn't support this language (unsupportedLanguageOrLocale)."
        case .exceededContextWindowSize:
            "The text was too long for the model (exceededContextWindowSize)."
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
}

extension Optional where Wrapped == String {
    var nonEmpty: String? { self?.nonEmpty }
}

extension String {
    /// "plum" → "Plum", as the chips of the note are written.
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }

    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
