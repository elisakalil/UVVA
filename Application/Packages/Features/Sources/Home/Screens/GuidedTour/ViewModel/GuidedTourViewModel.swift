import Foundation
import Observation

/// The tour on screen. The Home reads it to scroll; the overlay draws it; the app marks it seen on `onFinish`.
@MainActor @Observable
public final class GuidedTourViewModel {
    private(set) var tour = GuidedTour()
    let firstName: String
    private let onFinish: () -> Void

    public init(firstName: String, onFinish: @escaping () -> Void) {
        self.firstName = firstName
        self.onFinish = onFinish
    }

    var current: TourStep? { tour.step == 0 ? nil : TourStep.all[tour.step - 1] }

    /// "1 of 6", or "Tour" on the intro (HOME-R32).
    var counter: String {
        tour.step == 0 ? String(localized: "Tour", bundle: .module)
                       : String(localized: "\(tour.step) of \(GuidedTour.stepCount)", bundle: .module)
    }

    var nextTitle: String {
        tour.step == GuidedTour.stepCount ? String(localized: "Start", bundle: .module)
                                          : String(localized: "Next", bundle: .module)
    }

    func next() {
        tour.next()
        if tour.isFinished { onFinish() }
    }

    func back() { tour.back() }
    func pick(_ step: Int) { tour.pick(step) }
}
