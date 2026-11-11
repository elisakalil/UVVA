import Combine
import Foundation

@MainActor
public protocol EditPhotoViewModelProtocol: ObservableObject {
    var uiModel: EditPhotoUIModel { get }
    func prepare()
    func pickPhoto(loading load: @Sendable () async -> Data?) async
    func removePhoto()
    func savePhoto(_ photo: Data?) async -> Bool
}
