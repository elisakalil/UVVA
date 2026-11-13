import Core
import Foundation

/// Thousands of wines handed to a card or a sheet: the whole catalog for "Choose yourself", its suggestions for the
/// discovery sheet.
///
/// SwiftUI compares a view's inputs on every update, and an array of wines is compared wine by wine: with the catalog
/// in "Choose yourself", every frame of the Home's curtains spent seconds on the main thread comparing 10,000 wines.
/// A list is equal only to itself, the same read, which is all a view needs to know.
struct WineList: RandomAccessCollection, Equatable, Sendable {
    let wines: [Wine]
    let id = UUID()

    init(_ wines: [Wine]) { self.wines = wines }

    var startIndex: Int { wines.startIndex }
    var endIndex: Int { wines.endIndex }
    subscript(position: Int) -> Wine { wines[position] }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
