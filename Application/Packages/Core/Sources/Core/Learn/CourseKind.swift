import Foundation

/// The three tabs of Learn (LESSON-R01). A path module and a grape or region course follow the same rules.
public enum CourseKind: String, CaseIterable, Sendable {
    case path, grape, region

    /// From a course id: `path-01`, `grape-pinot-noir`, `region-pt-douro` (LESSON-R02).
    public init?(courseID: String) {
        guard let prefix = courseID.split(separator: "-").first, let kind = CourseKind(rawValue: String(prefix)) else {
            return nil
        }
        self = kind
    }
}
