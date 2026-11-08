import Foundation

/// An axis in "Reading by reading" (FRI-R19): its label, what the table does on it, and the range at the table.
struct AxisSpreadRowUIModel: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var spreadText: String
    var phrase: String
    var rangeText: String
}
