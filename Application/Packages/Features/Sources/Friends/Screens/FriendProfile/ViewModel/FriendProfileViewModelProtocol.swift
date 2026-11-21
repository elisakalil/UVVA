import Combine
import Core

@MainActor
public protocol FriendProfileViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: FriendProfileUIModel { get }
    func load() async
    func selectTab(_ tab: FriendProfileTab)
    /// FRI-R13: "Set the perfect dinner" opens the table for two in its sheet (FRI-R15a) and keeps it as the last
    /// table (FRI-R17).
    func setTable() async
    func closeTable()
    /// FRI-R13a: the choices of the perfect dinner.
    func toggleCourse(_ course: TableCourse)
    func pickFood(_ food: DinnerPreferences.Food)
    func toggleInSeason()
    func pickTime(_ time: DinnerPreferences.Time)
    func askToRemove()
    func cancelRemoval()
    func confirmRemoval() async
    /// FRI-R11: a wine of "Picks for [name]" opens Friend Wine.
    func openWine(_ id: String)
    /// FRI-R11a: a bottle of "Open this together" opens Friend Wine, read on both maps.
    func openTableWine(_ id: String)
    func closeWine()
    /// FRI-R11b: "Send to [name]" sends the open wine to the friend, who is told by a push.
    func sendWine() async
    /// FRI-R12a: "Scan a wine" opens the label scanner; the wine it reads opens in Friend Wine once it is gone.
    func scanWine()
    func closeScanner()
    func scannerDismissed()
    func openShare()
    func closeShare()
    func close()
}
