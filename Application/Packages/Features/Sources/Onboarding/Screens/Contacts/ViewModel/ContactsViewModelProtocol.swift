import Combine
import Core

@MainActor
protocol ContactsViewModelProtocol: ObservableObject {
    var uiModel: ContactsUIModel { get }
    func updateQuery(_ query: String)
    func back()
    func loadContacts() async
    func add(_ contactID: String) async
    func markInvited(_ contactID: String)
    func finishContacts()
}
