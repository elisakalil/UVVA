import Combine
import Core
import Foundation

@MainActor
public protocol EditPhoneViewModelProtocol: ObservableObject {
    var uiModel: EditPhoneUIModel { get }
    func prepare()
    func updateNational(_ value: String)
    func selectCountry(_ country: PhoneCountry)
    func savePhone(national: String, country: PhoneCountry) async -> Bool
}
