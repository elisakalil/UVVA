import Foundation

/// A filter word above a list: a level, a colour or a country.
struct FilterUIModel: Identifiable, Equatable {
    var id: String
    var label: String
    var isSelected: Bool
}
