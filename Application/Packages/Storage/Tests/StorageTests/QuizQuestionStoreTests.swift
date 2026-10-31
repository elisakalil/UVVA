import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct QuizQuestionStoreTests {
    @Test func questions_comeBackForEveryAxisAndVersion() async throws {
        let container = try AppStore.makeInMemoryContainer()
        _ = try await ContentImporter(modelContainer: container)
            .importIfNeeded(from: ContentSource(directory: try ContentFixture().write()), currentVersion: nil)
        let questions = try await QuizQuestionStore(modelContainer: container).questions()
        #expect(questions.count == 24)
        #expect(Set(questions.map(\.axis)) == Set(PalateAxis.allCases))
        #expect(questions.first { $0.axis == .acidity && $0.version == 2 }?.answers.count == 10)
    }
}
