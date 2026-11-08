import Combine

@MainActor
public protocol GroupTableViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: GroupTableUIModel { get }
    func load() async
    /// "Expand" / "Collapse" of "Reading by reading".
    func toggleReadings()
    func openShare()
    func closeShare()
    func close()
}
