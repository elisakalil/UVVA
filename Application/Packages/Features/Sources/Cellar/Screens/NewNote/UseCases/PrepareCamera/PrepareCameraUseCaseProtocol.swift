import Core

@MainActor
protocol PrepareCameraUseCaseProtocol {
    /// The camera access for the `+`: asks the system the first time (CELLAR-R15); a refusal stays (CELLAR-R22).
    func execute() async -> CameraAccess
}
