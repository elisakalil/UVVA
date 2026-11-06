import Foundation
import SwiftData

/// Personal state, separate from the bundled module content. CloudKit-compatible defaults.
@Model
public final class ModuleProgressEntity {
    public var courseId = ""
    public var state = 0
    public var lastOpenedAt: Date?
    public var completedAt: Date?

    init(courseId: String) { self.courseId = courseId }
}
