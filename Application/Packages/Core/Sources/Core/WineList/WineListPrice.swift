import Foundation

/// The prices at the end of a line of a wine list (WINELIST-R04): "Soalheiro 2023 ..... 42 €", "Barca Velha R$ 1.250,00",
/// "Arinto 7 / 28". A year is never a price: "Quinta do Crasto 2021" has none.
public enum WineListPrice {
    static let currencies = ["R$", "€", "£", "$", "EUR", "BRL", "USD", "GBP"]
    static let separators: Set<Character> = [".", "·", "…", "/", "|", "-", "–", "—", "_", ":", "•"]

    /// The line without its prices, and the highest of them: a row with a glass and a bottle is ordered by the bottle.
    public static func split(_ line: String) -> (text: String, price: Double?) {
        var tokens = line.split(whereSeparator: \.isWhitespace).map(String.init)
        var prices: [Double] = []
        var currencyNext = false
        while let last = tokens.last {
            let (number, hasCurrency, isOnlyCurrency) = read(last)
            if isOnlyCurrency || last.allSatisfy({ separators.contains($0) }) {
                currencyNext = currencyNext || isOnlyCurrency
                tokens.removeLast()
                continue
            }
            guard let number else { break }
            let markedAsMoney = hasCurrency || currencyNext || precedingCurrency(tokens)
            if !markedAsMoney, isYear(number, token: last) { break }
            guard (1...100_000).contains(number) else { break }
            prices.append(number)
            tokens.removeLast()
            currencyNext = false
            if precedingCurrency(tokens) { tokens.removeLast() }
        }
        let text = tokens.joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".·…/|-–—_:•")))
        return prices.isEmpty ? (line.trimmingCharacters(in: .whitespaces), nil) : (text, prices.max())
    }

    /// The currency the list is priced in: the symbol written most often, nil when it writes none.
    public static func currency(in lines: [String]) -> String? {
        var counts: [String: Int] = [:]
        for line in lines {
            if line.contains("R$") || line.uppercased().contains("BRL") { counts["R$", default: 0] += 1; continue }
            if line.contains("€") || line.uppercased().contains("EUR") { counts["€", default: 0] += 1 }
            if line.contains("£") { counts["£", default: 0] += 1 }
            if line.contains("$") { counts["$", default: 0] += 1 }
        }
        return counts.max { $0.value < $1.value || ($0.value == $1.value && $0.key > $1.key) }?.key
    }

    /// The number a token holds once its currency and leader dots are taken off, whether it carried a currency, and
    /// whether it was nothing but a currency.
    private static func read(_ token: String) -> (Double?, Bool, Bool) {
        var text = token
        var hasCurrency = false
        for symbol in currencies where text.uppercased().contains(symbol) {
            text = text.replacingOccurrences(of: symbol, with: "", options: .caseInsensitive)
            hasCurrency = true
        }
        text = String(text.drop { separators.contains($0) && $0 != "-" })
        while let last = text.last, separators.contains(last) || last == "," { text.removeLast() }
        if text.isEmpty { return (nil, hasCurrency, hasCurrency) }
        return (number(text), hasCurrency, false)
    }

    private static func precedingCurrency(_ tokens: [String]) -> Bool {
        guard let last = tokens.last else { return false }
        return currencies.contains { $0.caseInsensitiveCompare(last) == .orderedSame }
    }

    /// "42", "42,50", "42.50", "1.250,00", "1,250.00".
    static func number(_ text: String) -> Double? {
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") }),
              text.first?.isNumber == true else { return nil }
        let separatorsUsed = text.filter { $0 == "." || $0 == "," }
        guard let decimal = text.lastIndex(where: { $0 == "." || $0 == "," }) else { return Double(text) }
        let after = text[text.index(after: decimal)...]
        let before = text[..<decimal].filter(\.isNumber)
        // "1.250" or "1,250" alone are thousands; "42,5" and "42,50" are decimals.
        if separatorsUsed.count == 1, after.count == 3 { return Double(before + after) }
        guard after.count <= 2 else { return nil }
        return Double("\(before).\(after)")
    }

    private static func isYear(_ value: Double, token: String) -> Bool {
        value == value.rounded() && (1900...2040).contains(value) && token.filter(\.isNumber).count == 4
            && !token.contains(",") && !token.contains(".")
    }
}
