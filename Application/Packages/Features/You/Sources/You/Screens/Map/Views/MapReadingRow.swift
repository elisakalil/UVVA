import Foundation

struct MapReadingRow: Equatable, Identifiable {
    var name: String
    var level: Int
    var word: String
    var isStrong: Bool
    var id: String { name }
}
