import Combine
import Foundation

@MainActor
public protocol LessonPlayerViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: LessonPlayerUIModel { get }
    func back()
    func close()
    func begin()
    func primary()
    func reviewPrevious()
    func closeCertificate()
    func tapOption(_ option: Int)
    func tapWord(_ word: String)
    func tapRow(_ position: Int)
    func tapLeft(_ pair: Int)
    func tapRight(_ pair: Int)
}
