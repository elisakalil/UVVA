import Foundation

struct MapDeltaRow: Equatable, Identifiable {
    var name: String
    /// "+1.0", "−0.3", "—"
    var delta: String
    var id: String { name }
}
