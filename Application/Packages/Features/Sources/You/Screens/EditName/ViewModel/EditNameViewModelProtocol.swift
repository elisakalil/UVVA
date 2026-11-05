import Combine
import Core
import Foundation

@MainActor
public protocol EditNameViewModelProtocol: ObservableObject {
    var uiModel: EditNameUIModel { get }
    func prepare()
    func updateName(_ name: String)
    func saveName(_ name: String) async -> Bool
}
