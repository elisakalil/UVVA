import Combine
import Core

@MainActor
protocol WelcomeViewModelProtocol: ObservableObject {
    var uiModel: WelcomeUIModel { get }
    func checkICloud() async
    func openLegal(_ tab: LegalTab)
    func signIn() async
}
