import Core
import Foundation

@MainActor
protocol LoadCertificateSkillsUseCaseProtocol {
    func execute(_ course: Course) async -> [String]
}
