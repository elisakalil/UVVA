import Foundation

public struct GuidedTourUIModel {
    var step = 0
    var isFinished = false
    var firstName: String
    var stepCount = GuidedTour.stepCount
    var current: TourStep? { step == 0 ? nil : TourStep.all[step - 1] }
    var counter: String {
        step == 0 ? String(localized: "Tour", bundle: .module)
            : String(localized: "\(step) of \(stepCount)", bundle: .module)
    }
    var nextTitle: String {
        step == stepCount ? String(localized: "Start", bundle: .module) : String(localized: "Next", bundle: .module)
    }
    var introEyebrow = String(localized: "Your map is ready", bundle: .module)
    var welcome: String { String(localized: "Welcome in, \(firstName)", bundle: .module) }
    var introBody = String(localized: "A short walk through where things live in UVVA.", bundle: .module)
    var quickLook = String(localized: "A quick\nlook around", bundle: .module)
    var showTitle = String(localized: "Show me", bundle: .module)
    var backTitle = String(localized: "Back", bundle: .module)
    var backIcon = "chevron.left"
}
