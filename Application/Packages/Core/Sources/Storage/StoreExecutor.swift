import Foundation
import SwiftData

/// Where a store reads and writes: a serial queue of its own, with the store's `ModelContext` made on it.
///
/// `@ModelActor` runs its actor on SwiftData's `DefaultSerialModelExecutor`, which on the current SDKs runs every job
/// on the main thread, whatever thread made the actor. Every read of the stores (ranking the 10,000 wines of the
/// catalog for the Home, the Cellar's entries with their photos) then held the main thread: the app froze after a
/// new note, and the first note of a launch opened late behind the Home's first read.
public final class StoreExecutor: ModelExecutor, SerialExecutor, @unchecked Sendable {
    public let modelContainer: ModelContainer
    /// Only touched on `queue`, by the jobs of the store's actor.
    public let modelContext: ModelContext
    private let queue: DispatchSerialQueue

    public init(_ modelContainer: ModelContainer, label: String, qos: DispatchQoS = .userInitiated) {
        let queue = DispatchSerialQueue(label: label, qos: qos)
        self.queue = queue
        self.modelContainer = modelContainer
        // Made on the queue, so the context belongs to it rather than to the thread that made the store.
        modelContext = queue.sync { ModelContext(modelContainer) }
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        queue.async { job.runSynchronously(on: executor) }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    public func checkIsolated() {
        dispatchPrecondition(condition: .onQueue(queue))
    }
}

/// A `ModelActor` on a `StoreExecutor`: its `modelContext` and every one of its methods run on the store's own queue,
/// never on the main thread.
public protocol StoreActor: ModelActor {
    nonisolated var executor: StoreExecutor { get }
}

extension StoreActor {
    public nonisolated var modelExecutor: any ModelExecutor { executor }
    public nonisolated var modelContainer: ModelContainer { executor.modelContainer }
    public nonisolated var unownedExecutor: UnownedSerialExecutor { executor.asUnownedSerialExecutor() }
}
