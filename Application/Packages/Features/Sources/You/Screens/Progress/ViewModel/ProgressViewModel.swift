import Combine

@MainActor
public final class ProgressViewModel: ProgressViewModelProtocol {
    @Published public private(set) var uiModel: ProgressUIModel
    private let readModel: () -> YouContentModel
    private let coordinator: any YouCoordinatorProtocol

    init(readModel: @escaping () -> YouContentModel, coordinator: any YouCoordinatorProtocol) {
        self.readModel = readModel
        self.coordinator = coordinator
        uiModel = ProgressPresentationBuilder().build(from: readModel())

    }


    func present(_ model: YouContentModel) {
        uiModel = ProgressPresentationBuilder().build(from: model)
    }

    public func startCourse() {
        if let course = readModel().firstModule { coordinator.openCourse(course.id) }
        else { coordinator.openLearn() }
    }
}
