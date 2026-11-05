import Combine
import Core

@MainActor
protocol PhoneViewModelProtocol: ObservableObject {
    var uiModel: PhoneUIModel { get }
    func back()
    func press(_ digit: Character)
    func deleteDigit()
    func select(_ country: PhoneCountry)
    func skipPhone() async
    func continueWithPhone() async
}
