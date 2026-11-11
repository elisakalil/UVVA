import Combine
import Core
import Foundation

@MainActor
public protocol CertificatesViewModelProtocol: ObservableObject {
    var uiModel: CertificatesUIModel { get }
    func open(_ id: String)
}
