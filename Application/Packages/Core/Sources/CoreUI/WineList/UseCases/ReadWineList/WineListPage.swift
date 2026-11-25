import Core
import Foundation

/// What one photo of the list gave (WINELIST-R03).
struct WineListPage: Equatable {
    var wines: [WineListWine]
    var currency: String?
}
