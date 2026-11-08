import Foundation

/// A Quick add suggestion (FRI-R07): Add, or Requested once asked (FRI-R08), and `×` (FRI-R09).
struct QuickAddRowUIModel: Identifiable, Equatable {
    var id: String
    var name: String
    var signature: String
    var isRequested: Bool
}
