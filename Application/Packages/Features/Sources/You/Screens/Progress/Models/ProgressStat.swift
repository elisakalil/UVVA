import Foundation

struct ProgressStat: Equatable, Identifiable {
    var value: String
    var label: String
    var items: [ProgressStatItem] = []
    var id: String { label }
}

struct ProgressStatItem: Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
}
