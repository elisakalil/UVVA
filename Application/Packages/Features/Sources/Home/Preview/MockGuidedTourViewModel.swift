#if DEBUG
import Combine

@MainActor
final class MockGuidedTourViewModel: GuidedTourViewModelProtocol {
    @Published var uiModel = GuidedTourUIModel(firstName: "Elisa")
    func next() { if uiModel.step < uiModel.stepCount { uiModel.step += 1 } }
    func back() { if uiModel.step > 0 { uiModel.step -= 1 } }
    func pick(_ step: Int) { if (1...uiModel.stepCount).contains(step) { uiModel.step = step } }
}
#endif
