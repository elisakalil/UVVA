import Combine

@MainActor
public final class ProgressViewModel: ProgressViewModelProtocol {
    @Published public private(set) var uiModel: ProgressUIModel
    private let coordinator: any YouCoordinatorProtocol

    init(readModel: @escaping () -> YouContentModel, coordinator: any YouCoordinatorProtocol) {
        self.coordinator = coordinator
        uiModel = ProgressPresentationBuilder().build(from: readModel())

    }


    func present(_ model: YouContentModel) {
        uiModel = ProgressPresentationBuilder().build(from: model)
    }

    public func startCourse() {
        guard uiModel.cta != nil else { return }
        if let id = uiModel.suggestedCourseID { coordinator.openCourse(id) }
        else { coordinator.openLearn() }
    }
}
