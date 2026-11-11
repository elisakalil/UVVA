import Combine
import Core
import Foundation

@MainActor
public protocol SettingsViewModelProtocol: ObservableObject {
    var uiModel: SettingsUIModel { get }
    associatedtype EditNameModel: EditNameViewModelProtocol
    var editName: EditNameModel { get }
    associatedtype EditPhoneModel: EditPhoneViewModelProtocol
    var editPhone: EditPhoneModel { get }
    associatedtype EditPhotoModel: EditPhotoViewModelProtocol
    var editPhoto: EditPhotoModel { get }
    associatedtype ReminderModel: ReminderViewModelProtocol
    var reminder: ReminderModel { get }
    associatedtype CertificatesModel: CertificatesViewModelProtocol
    var certificates: CertificatesModel { get }
    func setMapPublic(_ isPublic: Bool) async
    func signOut() async
    func deleteAccount() async
    func dismissDeleteFailure()
}
