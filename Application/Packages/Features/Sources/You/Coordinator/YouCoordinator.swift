/// Bridges destinations and session results to the application without importing other Features.
@MainActor
public struct YouCoordinator: YouCoordinatorProtocol {
    private let onRedoMap: () -> Void
    private let onOpenLearn: () -> Void
    private let onOpenCourse: (String) -> Void
    private let onOpenCertificate: (String) -> Void
    private let onSignOut: () -> Void
    private let onAccountDeleted: () -> Void

    public init(onRedoMap: @escaping () -> Void, onOpenLearn: @escaping () -> Void,
                onOpenCourse: @escaping (String) -> Void, onOpenCertificate: @escaping (String) -> Void,
                onSignOut: @escaping () -> Void, onAccountDeleted: @escaping () -> Void) {
        self.onRedoMap = onRedoMap
        self.onOpenLearn = onOpenLearn
        self.onOpenCourse = onOpenCourse
        self.onOpenCertificate = onOpenCertificate
        self.onSignOut = onSignOut
        self.onAccountDeleted = onAccountDeleted
    }

    public func redoMap() { onRedoMap() }
    public func openLearn() { onOpenLearn() }
    public func openCourse(_ id: String) { onOpenCourse(id) }
    public func openCertificate(_ id: String) { onOpenCertificate(id) }
    public func signOut() { onSignOut() }
    public func accountDeleted() { onAccountDeleted() }
}
