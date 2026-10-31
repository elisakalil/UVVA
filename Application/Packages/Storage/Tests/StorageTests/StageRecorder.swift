import Foundation
import Storage
import Synchronization

/// Collects the stages reported by the importer, from any thread.
final class StageRecorder: Sendable {
    private let stages = Mutex<[ContentImportStage]>([])

    func append(_ stage: ContentImportStage) { stages.withLock { $0.append(stage) } }
    var all: [ContentImportStage] { stages.withLock { $0 } }
}
