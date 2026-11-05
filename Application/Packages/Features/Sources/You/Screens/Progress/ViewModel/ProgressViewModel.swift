import Combine

@MainActor
public final class ProgressViewModel: ProgressViewModelProtocol {
    @Published public private(set) var uiModel: ProgressUIModel
    private var subscription: AnyCancellable?
    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol

    init(state: YouState, coordinator: any YouCoordinatorProtocol) {
        self.state = state
        self.coordinator = coordinator
        uiModel = ProgressPresentationBuilder().build(from: state.content)
        subscription = state.$content.sink { [weak self] content in
            self?.uiModel = ProgressPresentationBuilder().build(from: content)
        }
    }


    public func startCourse() {
        if let course = state.content.firstModule { coordinator.openCourse(course.id) }
        else { coordinator.openLearn() }
    }
}
