import Combine

@MainActor
public protocol GuidedTourViewModelProtocol: ObservableObject {
    var uiModel: GuidedTourUIModel { get }
    func next()
    func back()
    func pick(_ step: Int)
}
