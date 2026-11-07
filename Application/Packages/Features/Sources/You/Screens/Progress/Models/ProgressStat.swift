import Foundation

struct ProgressStat: Equatable, Identifiable {
    var value: String
    var label: String
    var items: [ProgressStatItem] = []
    var id: String { label }

    var groups: [ProgressStatGroup] {
        Dictionary(grouping: items, by: \.group)
            .map { ProgressStatGroup(title: $0.key, items: $0.value) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

struct ProgressStatGroup: Identifiable {
    let title: String
    let items: [ProgressStatItem]
    var id: String { title }
}

struct ProgressStatItem: Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var group: String
    var chips: [String]
}
