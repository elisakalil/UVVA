import Foundation

/// "Say it or show it" (WINELIST-R08): the line for the waiter, what to ask for if the wine is gone, and where it is
/// on the list.
struct WineListAskUIModel: Equatable {
    var label = ""
    var line = ""
    var fallback = ""
    var place = ""
    var language = WineListLanguage.english
}
