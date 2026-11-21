import Foundation

/// An axis in "Reading by reading" (FRI-R19): its label, what the table does on it, and the range at the table,
/// written ("6–8") and drawn along a line (each 0...1): the lowest and the highest reading, and the middle.
struct AxisSpreadRowUIModel: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var spreadText: String
    var phrase: String
    var rangeText: String
    var low: Double = 0
    var high: Double = 0
    var middle: Double = 0
    /// Same or Closest: the name stands out.
    var isClose = false
}
