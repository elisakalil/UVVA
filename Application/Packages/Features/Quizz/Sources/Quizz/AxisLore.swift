import Core
import Foundation

/// What a high or a low value on each axis says about the person (QUIZZ.md, Anexo A).
enum AxisLore {
    static func high(_ axis: PalateAxis) -> String {
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

    static func low(_ axis: PalateAxis) -> String {
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
}
