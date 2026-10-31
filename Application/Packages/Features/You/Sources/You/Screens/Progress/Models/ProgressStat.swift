import Foundation

struct ProgressStat: Equatable, Identifiable {
    var value: String
    var label: String
    var id: String { label }
}
