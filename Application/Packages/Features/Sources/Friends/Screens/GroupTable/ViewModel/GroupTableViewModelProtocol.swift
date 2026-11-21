import Combine
import Core

@MainActor
public protocol GroupTableViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: GroupTableUIModel { get }
    func load() async
    /// "Expand" / "Collapse" of "Reading by reading".
    func toggleReadings()
    /// FRI-R13: builds the dinner chosen and opens it in its sheet (FRI-R15a).
    func setTable() async
    func closeTable()
    /// FRI-R13a: the choices of the dinner.
    func toggleCourse(_ course: TableCourse)
    func pickFood(_ food: DinnerPreferences.Food)
    func toggleInSeason()
    func pickTime(_ time: DinnerPreferences.Time)
    /// A bottle of "Open this together" opens Friend Wine, read on every map at the table.
    func openTableWine(_ id: String)
    func closeWine()
    /// Sends the open wine to everyone at the table.
    func sendWine() async
    /// `+`: the label scanner; the wine it reads opens in Friend Wine once it is gone.
    func scanWine()
    func closeScanner()
    func scannerDismissed()
    func openShare()
    func closeShare()
    func close()
}
