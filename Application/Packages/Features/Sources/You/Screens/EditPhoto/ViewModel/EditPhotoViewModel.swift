import Combine
import Core
import Foundation

@MainActor
public final class EditPhotoViewModel: EditPhotoViewModelProtocol {
    @Published public private(set) var uiModel = EditPhotoUIModel()
    private let onProfileSaved: (Profile) -> Void
    private let readModel: () -> YouContentModel
    private let savePhotoUseCase: any SavePhotoUseCaseProtocol
    private let processPhoto: @Sendable (Data) async -> Data?

    init(readModel: @escaping () -> YouContentModel, onProfileSaved: @escaping (Profile) -> Void,
         savePhotoUseCase: any SavePhotoUseCaseProtocol,
         processPhoto: @escaping @Sendable (Data) async -> Data? = EditPhotoViewModel.squareAndWash) {
        self.readModel = readModel
        self.onProfileSaved = onProfileSaved
        self.savePhotoUseCase = savePhotoUseCase
        self.processPhoto = processPhoto
    }

    public func prepare() {
        let photo = readModel().profile?.photo
        uiModel.photo = photo
        uiModel.savedPhoto = photo
        uiModel.notice = nil
    }

    /// Cut to a small square and washed in the blues of the sky (YOU-R14a), away from the main thread.
    nonisolated static func squareAndWash(_ data: Data) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            PhotoResizer.squareJPEG(data).flatMap(PhotoWash.wash)
        }.value
    }

    /// The photo becomes the draft once it is read, cut and washed. Nothing is saved yet.
    public func pickPhoto(loading load: @Sendable () async -> Data?) async {
        guard !uiModel.isLoading else { return }
        uiModel.isLoading = true
        uiModel.notice = nil
        defer { uiModel.isLoading = false }
        guard let data = await load(), let jpeg = await processPhoto(data) else {
            uiModel.notice = uiModel.thatPhotoCouldNotBeText
            return
        }
        uiModel.photo = jpeg
    }

    public func removePhoto() {
        uiModel.photo = nil
        uiModel.notice = nil
    }

    public func savePhoto(_ photo: Data?) async -> Bool {
        guard let profile = readModel().profile, !uiModel.isSaving else { return false }
        uiModel.isSaving = true
        uiModel.notice = nil
        defer { uiModel.isSaving = false }
        do {
            onProfileSaved(try await savePhotoUseCase.execute(photo, profile: profile))
            return true
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
            return false
        }
    }
}
