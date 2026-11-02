import Core
import Foundation

/// What a high or a low value on each axis says about the person (QUIZZ.md, Anexo A).
public enum AxisLore {
    public static func high(_ axis: PalateAxis) -> String {
        switch axis {
        case .sweetness: String(localized: "a little residual sugar reads as generosity to you, not as a flaw", bundle: .module)
        case .acidity: String(localized: "acidity is the first thing you notice, and it is what keeps a wine awake for you", bundle: .module)
        case .tannin: String(localized: "you want grip, the drying pull that holds a red upright", bundle: .module)
        case .body: String(localized: "you want weight in the glass, something that coats and stays", bundle: .module)
        case .fruit: String(localized: "ripe fruit is the point for you, not a beginner's phase to grow out of", bundle: .module)
        case .floral: String(localized: "perfume pulls you in before structure ever does", bundle: .module)
        case .oak: String(localized: "vanilla, smoke and toast are part of the pleasure, not a cover-up", bundle: .module)
        case .spice: String(localized: "pepper and clove are what you go looking for", bundle: .module)
        }
    }

    public static func low(_ axis: PalateAxis) -> String {
        switch axis {
        case .sweetness: String(localized: "sugar reads as a flaw to you, and dry means dry", bundle: .module)
        case .acidity: String(localized: "sharpness tires you out; you want a rounder line through the middle", bundle: .module)
        case .tannin: String(localized: "tannin gets in the way for you; you want fruit without the scaffolding", bundle: .module)
        case .body: String(localized: "you want a wine that stays light and gets out of the way", bundle: .module)
        case .fruit: String(localized: "you look past fruit for earth, salt and stone", bundle: .module)
        case .floral: String(localized: "floral aromatics read as soap to you", bundle: .module)
        case .oak: String(localized: "you want the grape, not the barrel", bundle: .module)
        case .spice: String(localized: "spice distracts you from the fruit", bundle: .module)
        }
    }

    // MARK: QUIZ-R14a · Maps with no single top or bottom

    /// The eight axes on one level.
    public static func flat(_ tone: AxisTone) -> String {
        switch tone {
        case .low: String(localized: "every axis sits low on your map: you want a quiet wine, one that whispers instead of making a point", bundle: .module)
        case .neutral: String(localized: "every axis sits in the middle: you want balance, a wine where nothing is too much or too little", bundle: .module)
        case .high: String(localized: "every axis runs high on your map: you want a wine that does a lot at once, with nothing held back", bundle: .module)
        }
    }

    /// Three or more axes tied on a high top.
    public static var mostHigh: String { String(localized: "most of the map runs high: you want a wine that does a lot at once, with no single axis in charge", bundle: .module) }
    /// Three or more axes tied on a low bottom.
    public static var mostLow: String { String(localized: "most of the map stays quiet: you want restraint more than power", bundle: .module) }
    /// A top that is not high.
    public static var nothingHigh: String { String(localized: "nothing on the map climbs high, so no single part of a wine has to lead", bundle: .module) }
    /// A bottom that is not low.
    public static var nothingLow: String { String(localized: "nothing on the map is truly low: you leave room for every part of a wine", bundle: .module) }
}
