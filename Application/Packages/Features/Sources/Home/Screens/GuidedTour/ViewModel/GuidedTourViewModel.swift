import Foundation
import Combine

/// The tour on screen. The Home reads it to scroll; the overlay draws it; the app marks it seen on `onFinish`.
@MainActor
public final class GuidedTourViewModel: GuidedTourViewModelProtocol {
    @Published public private(set) var uiModel: GuidedTourUIModel
    private(set) var tour = GuidedTour() { didSet { refresh() } }
    let firstName: String
    private let onFinish: () -> Void

    public init(firstName: String, onFinish: @escaping () -> Void) {
        self.firstName = firstName
        self.uiModel = GuidedTourUIModel(firstName: firstName)
        self.onFinish = onFinish
    }

    public func next() {
        guard !tour.isFinished else { return }
        tour.next()
        if tour.isFinished { onFinish() }
    }

    public func back() {
        guard !tour.isFinished else { return }
        tour.back()
    }
    public func pick(_ step: Int) {
        guard !tour.isFinished else { return }
        tour.pick(step)
    }
    private func refresh() {
        uiModel = GuidedTourUIModel(step: tour.step, isFinished: tour.isFinished, firstName: firstName)
    }
}
