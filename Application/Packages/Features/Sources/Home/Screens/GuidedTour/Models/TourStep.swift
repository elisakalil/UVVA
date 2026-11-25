import DesignSystem
import Foundation

/// What a step of the tour says and where it points (HOME-R31).
struct TourStep {
    var title: String
    var body: String
    /// The `spotlightAnchor` id of the area.
    var target: String
    /// Used when the target is not on screen (HOME, step 1 without a suggestion).
    var fallback: String?
    var cornerRadius: CGFloat
    /// How far the light reaches past the area.
    var padding: CGFloat

    /// HOME-R31: five steps; the Hero comes first, the tabs last.
    static let all: [TourStep] = [
        TourStep(title: String(localized: "Your best match", bundle: .module),
                 body: String(localized: "First on your Home is the wine with the highest match to your map, with a dish to pour it with. It changes as your map does.", bundle: .module),
                 target: HomeSpotlightID.today, fallback: HomeSpotlightID.friends, cornerRadius: 38, padding: 6),
        TourStep(title: String(localized: "Scan a label", bundle: .module),
                 body: String(localized: "Tap + and photograph the front and back of a bottle. UVVA reads the label and keeps the wine in your cellar. Every wine you rate moves your map.", bundle: .module),
                 target: HomeSpotlightID.scan, cornerRadius: 23, padding: 6),
        TourStep(title: String(localized: "Learn about wine", bundle: .module),
                 body: String(localized: "Short lessons on regions, grapes and tasting, a few minutes at a time. Finish a course and share your certificate.", bundle: .module),
                 target: AppTab.learn.spotlightID, cornerRadius: 24, padding: 8),
        TourStep(title: String(localized: "Your cellar", bundle: .module),
                 body: String(localized: "The wines you have tasted, with your rating, and the ones you want to try, each with its match to your map.", bundle: .module),
                 target: AppTab.cellar.spotlightID, cornerRadius: 24, padding: 8),
        TourStep(title: String(localized: "Set a table", bundle: .module),
                 body: String(localized: "Add friends and see how your palates compare. Set a table and UVVA picks three bottles and a dinner menu for everyone.", bundle: .module),
                 target: AppTab.friends.spotlightID, cornerRadius: 24, padding: 8)
    ]
}
