import Core

/// Routes exits to the application; question transitions remain in QuizFlow.
@MainActor
public struct QuizCoordinator: QuizCoordinatorProtocol {
    private let entry: QuizEntry
    private let onExit: (QuizExit) -> Void

    public init(entry: QuizEntry, onExit: @escaping (QuizExit) -> Void) {
        self.entry = entry
        self.onExit = onExit
    }

    public func finish() { onExit(QuizExit(for: entry)) }

    public func leave() {
        guard entry == .redo else { return }
        onExit(.youMap)
    }
}
