import Foundation

/// The words of Friend Wine (FRI-R11a, R12a). The match is with the friend's map, or with the two maps together for
/// a scanned wine, so every line says whose.
struct FriendWineResourcesUIModel {
    var findWineText = String(localized: "Find the wine", bundle: .module)
    var backText = String(localized: "Back", bundle: .module)
    var addToCellarText = String(localized: "Add to cellar", bundle: .module)
    var inCellarText = String(localized: "In your cellar", bundle: .module)
    var pairingsText = String(localized: "Pairings", bundle: .module)
    var serveText = String(localized: "How to serve", bundle: .module)
    var wineMapText = String(localized: "The map of this wine", bundle: .module)
    var wineLegendText = String(localized: "This wine", bundle: .module)
    var overlapLegendText = String(localized: "In common", bundle: .module)
    var youText = String(localized: "You", bundle: .module)
    var yourTwoMapsText = String(localized: "your two maps", bundle: .module)
    var youTwoDrinkText = String(localized: "you two usually drink", bundle: .module)
    var yourMapText = String(localized: "your map", bundle: .module)
    var youDrinkText = String(localized: "you usually drink", bundle: .module)
    var yourMapLegend = String(localized: "Your map", bundle: .module)
    var sendingText = String(localized: "Sending…", bundle: .module)
    var sendFailedText = String(localized: "It did not send. Try again.", bundle: .module)

    /// FRI-R11b: "Send to Marina".
    func sendTo(_ name: String) -> String { String(localized: "Send to \(name)", bundle: .module) }

    /// FRI-R11b: "Sent to Marina", once it has gone.
    func sentTo(_ name: String) -> String { String(localized: "Sent to \(name)", bundle: .module) }

    /// FRI-R11c: "Marina sent you this wine", over a wine received.
    func sentYou(_ name: String) -> String { String(localized: "\(name) sent you this wine", bundle: .module) }

    /// "Marina's map".
    func friendMap(_ name: String) -> String { String(localized: "\(name)'s map", bundle: .module) }

    /// "Marina usually drinks".
    func friendDrinks(_ name: String) -> String { String(localized: "\(name) usually drinks", bundle: .module) }

    /// "match with Marina's map", or "match with your two maps", beside the percentage.
    func matchCaption(_ map: String) -> String { String(localized: "match with \(map)", bundle: .module) }

    /// "This wine and Marina", "This wine and you two", over the two maps.
    func comparison(_ who: String) -> String { String(localized: "This wine and \(who)", bundle: .module) }

    var youTwoText: String { String(localized: "you two", bundle: .module) }

    /// "Your two maps", in the legend of a scanned wine's comparison.
    var yourTwoMapsLegend: String { String(localized: "Your two maps", bundle: .module) }

    // MARK: A group table (FRI-R19)

    var sendToTableText = String(localized: "Send to the table", bundle: .module)
    var sentToTableText = String(localized: "Sent to the table", bundle: .module)

    /// "your 4 maps".
    func yourMaps(_ count: Int) -> String { String(localized: "your \(count) maps", bundle: .module) }

    /// "Your 4 maps", in the legend of the comparison.
    func yourMapsLegend(_ count: Int) -> String { String(localized: "Your \(count) maps", bundle: .module) }

    /// "the 4 of you usually drink".
    func youAllDrink(_ count: Int) -> String { String(localized: "the \(count) of you usually drink", bundle: .module) }

    /// "the 4 of you", in "This wine and the 4 of you".
    func theFewOfYou(_ count: Int) -> String { String(localized: "the \(count) of you", bundle: .module) }

    // MARK: What the wine shares with the map (as HOME-R10b, for the friend or the two of you)

    func highInBoth(_ first: String, _ second: String, _ map: String) -> String {
        String(localized: "High in \(first) and \(second), like \(map).", bundle: .module)
    }

    func highIn(_ axis: String, _ map: String) -> String {
        String(localized: "High in \(axis), like \(map).", bundle: .module)
    }

    func bolder(_ map: String) -> String { String(localized: "Bolder than \(map), which has no high axis.", bundle: .module) }

    func quiet(_ map: String) -> String { String(localized: "Quiet on every axis, like \(map).", bundle: .module) }

    func notHighIn(_ axis: String, _ map: String) -> String {
        String(localized: "Not high in \(axis), the strongest axis on \(map).", bundle: .module)
    }

    func different(_ map: String) -> String {
        String(localized: "Different from the strongest axes on \(map).", bundle: .module)
    }

    // MARK: Where they part

    func close(_ map: String) -> String { String(localized: "Close to \(map) on every axis.", bundle: .module) }

    /// "More oak than Marina usually drinks."
    func more(_ axis: String, _ drinker: String) -> String {
        String(localized: "More \(axis) than \(drinker).", bundle: .module)
    }

    func less(_ axis: String, _ drinker: String) -> String {
        String(localized: "Less \(axis) than \(drinker).", bundle: .module)
    }
}
