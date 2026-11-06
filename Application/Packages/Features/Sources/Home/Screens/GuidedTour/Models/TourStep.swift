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

    static let all: [TourStep] = [
        TourStep(title: String(localized: "A pairing drawn for your palate", bundle: .module),
                 body: String(localized: "Every day UVVA designs a full experience around your map: a wine that hits the notes you love loudest, and a recipe built to balance everything else.", bundle: .module),
                 target: HomeSpotlightID.today, fallback: HomeSpotlightID.friends, cornerRadius: 38, padding: 6),
        TourStep(title: String(localized: "Choose your wine", bundle: .module),
                 body: String(localized: "Pick a direction, a type, a region and up to three notes. UVVA finds the bottle closest to your map for tonight.", bundle: .module),
                 target: HomeSpotlightID.chooseYourWine, cornerRadius: 30, padding: 8),
        TourStep(title: String(localized: "Scan a label", bundle: .module),
                 body: String(localized: "Tap + and point the camera at any bottle. UVVA reads the label, classifies the wine and adds it to your cellar. Every note you save moves your map.", bundle: .module),
                 target: HomeSpotlightID.scan, cornerRadius: 23, padding: 6),
        TourStep(title: String(localized: "Learn the wines you love", bundle: .module),
                 body: String(localized: "Get to know the region you keep coming back to, the grape behind your favourite bottle, and what to look for in the glass. Five minutes at a time.", bundle: .module),
                 target: AppTab.learn.spotlightID, cornerRadius: 24, padding: 8),
        TourStep(title: String(localized: "Your cellar", bundle: .module),
                 body: String(localized: "Wines you have tasted and wines you want to try, each one measured against your map.", bundle: .module),
                 target: AppTab.cellar.spotlightID, cornerRadius: 24, padding: 8),
        TourStep(title: String(localized: "Set a table", bundle: .module),
                 body: String(localized: "Invite the people you drink with. UVVA reads every map at the table and suggests one bottle for all of you.", bundle: .module),
                 target: AppTab.friends.spotlightID, cornerRadius: 24, padding: 8)
    ]
}
