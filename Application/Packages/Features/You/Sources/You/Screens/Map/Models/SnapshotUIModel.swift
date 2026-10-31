import Foundation

/// One dot of the Over time line.
struct SnapshotUIModel: Equatable, Identifiable {
    var id: Int
    /// "First map", "Aug", "Today"
    var label: String
    /// "First map · 0 wines rated", "8 wines rated", "Today · 27 wines rated"
    var detail: String
    var isNew: Bool
}
