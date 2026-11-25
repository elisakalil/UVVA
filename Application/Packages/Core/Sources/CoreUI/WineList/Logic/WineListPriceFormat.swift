import Foundation

/// A price as the list writes it (WINELIST-R04): "42 €", "R$ 180", "$42", or the number alone.
struct WineListPriceFormat {
    var currency: String?

    func text(_ price: Double) -> String {
        let number = price == price.rounded()
            ? String(Int(price))
            : price.formatted(.number.precision(.fractionLength(2)))
        switch currency {
        case "€": return "\(number) €"
        case "R$": return "R$ \(number)"
        case let symbol?: return "\(symbol)\(number)"
        case nil: return number
        }
    }
}
