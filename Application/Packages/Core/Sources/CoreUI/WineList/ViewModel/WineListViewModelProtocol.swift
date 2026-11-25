import Combine
import Core
import Foundation

@MainActor
public protocol WineListViewModelProtocol: ObservableObject {
    var uiModel: WineListUIModel { get }
    /// Checks the camera and reads the palates and recipes the ranking needs.
    func start() async
    /// A page of the list: `photo` is read at full size (WINELIST-R03).
    func capture(_ photo: Data) async
    /// "Use this list".
    func useList()
    /// One screen back: from the questions to the camera, from the wines to the questions.
    func back()
    func toggleDish(_ id: String)
    func chooseBudget(_ id: String)
    func togglePerson(_ id: String)
    /// "Tell me what to order" (WINELIST-R07).
    func showPicks()
    /// "How to ask for it" on a wine (WINELIST-R08).
    func ask(_ id: String)
    func chooseLanguage(_ language: String)
    /// "It's on the table · add to Cellar".
    func addToCellar()
}
