import Core
import Foundation

/// What each level of an axis means in a glass (QUIZ-R05, R04a): one description per position 0...9 on the ruler,
/// the same for a wine and for a map. A map at floral 8 asks for a very floral wine; a wine at floral 8 is one.
public enum AxisLevels {
    /// The description of a level, 0...9, on an axis.
    public static func word(_ level: Int, on axis: PalateAxis) -> String {
        let words = words(axis)
        return words[min(max(level, 0), words.count - 1)]
    }

    // swiftlint:disable:next function_body_length
    static func words(_ axis: PalateAxis) -> [String] {
        switch axis {
        case .floral: [
            String(localized: "No flowers", bundle: .module),
            String(localized: "Barely floral", bundle: .module),
            String(localized: "A faint blossom", bundle: .module),
            String(localized: "A hint of flowers", bundle: .module),
            String(localized: "Lightly floral", bundle: .module),
            String(localized: "Gently floral", bundle: .module),
            String(localized: "Clearly floral", bundle: .module),
            String(localized: "Floral", bundle: .module),
            String(localized: "Very floral", bundle: .module),
            String(localized: "Perfumed", bundle: .module)
        ]
        case .body: [
            String(localized: "Feather-light", bundle: .module),
            String(localized: "Light", bundle: .module),
            String(localized: "Light to medium", bundle: .module),
            String(localized: "Medium-light", bundle: .module),
            String(localized: "Medium", bundle: .module),
            String(localized: "Medium, rounded", bundle: .module),
            String(localized: "Medium-full", bundle: .module),
            String(localized: "Full", bundle: .module),
            String(localized: "Full and broad", bundle: .module),
            String(localized: "Mouth-filling", bundle: .module)
        ]
        case .tannin: [
            String(localized: "No grip, like a white", bundle: .module),
            String(localized: "Barely any grip", bundle: .module),
            String(localized: "A whisper of grip", bundle: .module),
            String(localized: "Soft, like a light red", bundle: .module),
            String(localized: "Gentle grip", bundle: .module),
            String(localized: "Medium grip", bundle: .module),
            String(localized: "Firm", bundle: .module),
            String(localized: "Firm and drying", bundle: .module),
            String(localized: "Grippy", bundle: .module),
            String(localized: "Powerful, mouth-drying", bundle: .module)
        ]
        case .spice: [
            String(localized: "No spice", bundle: .module),
            String(localized: "Barely spiced", bundle: .module),
            String(localized: "A touch of pepper", bundle: .module),
            String(localized: "Lightly spiced", bundle: .module),
            String(localized: "Some spice", bundle: .module),
            String(localized: "Gently spicy", bundle: .module),
            String(localized: "Spicy", bundle: .module),
            String(localized: "Clearly spicy", bundle: .module),
            String(localized: "Very spicy", bundle: .module),
            String(localized: "Peppery and bold", bundle: .module)
        ]
        case .oak: [
            String(localized: "Unoaked", bundle: .module),
            String(localized: "Barely any oak", bundle: .module),
            String(localized: "Old oak, hardly felt", bundle: .module),
            String(localized: "A hint of oak", bundle: .module),
            String(localized: "Light oak", bundle: .module),
            String(localized: "Some oak", bundle: .module),
            String(localized: "Noticeable oak", bundle: .module),
            String(localized: "Oaky, vanilla and toast", bundle: .module),
            String(localized: "Very oaky", bundle: .module),
            String(localized: "New oak up front", bundle: .module)
        ]
        case .sweetness: [
            String(localized: "Bone dry", bundle: .module),
            String(localized: "Dry", bundle: .module),
            String(localized: "Dry", bundle: .module),
            String(localized: "Dry, a touch of sugar", bundle: .module),
            String(localized: "Just off-dry", bundle: .module),
            String(localized: "Off-dry", bundle: .module),
            String(localized: "Medium-dry", bundle: .module),
            String(localized: "Medium-sweet", bundle: .module),
            String(localized: "Sweet", bundle: .module),
            String(localized: "Lusciously sweet", bundle: .module)
        ]
        case .acidity: [
            String(localized: "Flat, very soft", bundle: .module),
            String(localized: "Soft", bundle: .module),
            String(localized: "Gentle", bundle: .module),
            String(localized: "Moderate", bundle: .module),
            String(localized: "Balanced", bundle: .module),
            String(localized: "Fresh", bundle: .module),
            String(localized: "Bright", bundle: .module),
            String(localized: "Crisp", bundle: .module),
            String(localized: "Zesty", bundle: .module),
            String(localized: "Racy, mouth-watering", bundle: .module)
        ]
        case .fruit: [
            String(localized: "Restrained, little fruit", bundle: .module),
            String(localized: "Subtle fruit", bundle: .module),
            String(localized: "Light fruit", bundle: .module),
            String(localized: "Some fruit", bundle: .module),
            String(localized: "Fruity", bundle: .module),
            String(localized: "Clearly fruity", bundle: .module),
            String(localized: "Ripe fruit", bundle: .module),
            String(localized: "Juicy", bundle: .module),
            String(localized: "Lush fruit", bundle: .module),
            String(localized: "Bursting with fruit", bundle: .module)
        ]
        }
    }
}
