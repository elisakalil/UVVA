import Core

@MainActor
struct PrepareCameraUseCase: PrepareCameraUseCaseProtocol {
    let camera: any CameraAuthorizing

    func execute() async -> CameraAccess {
        switch await camera.access() {
        case .notDetermined: await camera.requestAccess() ? .authorized : .denied
        case let access: access
        }
    }
}
