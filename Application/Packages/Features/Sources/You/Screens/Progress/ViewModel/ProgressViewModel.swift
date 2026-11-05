import Observation

@MainActor @Observable
final class ProgressViewModel {
    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol

    init(state: YouState, coordinator: any YouCoordinatorProtocol) {
        self.state = state
        self.coordinator = coordinator
    }

    var model: ProgressUIModel { ProgressPresentationBuilder().build(from: state.content) }

    func startCourse() {
        if let course = state.content.firstModule { coordinator.openCourse(course.id) }
        else { coordinator.openLearn() }
    }
}
