import Core
import Foundation
import Match

/// "Say it or show it" (WINELIST-R08), written in the restaurant's language whatever the phone's: the line to order
/// the wine as the list prints it, and what to ask for if it is gone, from the wine's type and its highest axes.
struct WineListAskWriter {
    var language: WineListLanguage
    var format: WineListPriceFormat

    func ask(for pick: WineListPick) -> WineListAskUIModel {
        let entry = pick.wine.entry
        let number = language == .english ? "No." : "Nº"
        let place = [entry.section.map { "\($0) · \(number) \(entry.position)" }, entry.price.map(format.text)]
            .compactMap { $0 }.joined(separator: " · ")
        let around = entry.price.map { format.text(WineListBudget.round($0 - 2.5)) }
        let style = describe(pick.wine.wine)
        switch language {
        case .english:
            return WineListAskUIModel(
                label: "Say it or show it",
                line: "Could we have the \(entry.name), please?",
                fallback: around.map { "If it’s gone: \(style), around \($0)." } ?? "If it’s gone: \(style).",
                place: place, language: language)
        case .portuguese:
            return WineListAskUIModel(
                label: "Diga ou mostre",
                line: "Pode nos trazer o \(entry.name), por favor?",
                fallback: around.map { "Se não houver: \(style), por volta de \($0)." } ?? "Se não houver: \(style).",
                place: place, language: language)
        }
    }

    /// "a red, fresh and fruity", "um branco leve e fresco".
    func describe(_ wine: Wine) -> String {
        let type = typeWord(wine.type)
        var traits = PalateAxis.allCases
            .filter { AxisTone(wine.profile, $0) == .high }
            .sorted { WineRuler.position(of: wine.profile[$0], on: $0) > WineRuler.position(of: wine.profile[$1], on: $1) }
            .prefix(2)
            .map(trait)
        if AxisTone(wine.profile, .body) == .low, traits.count < 2 { traits.insert(light, at: 0) }
        guard !traits.isEmpty else { return type }
        let joined = traits.joined(separator: language == .english ? " and " : " e ")
        return language == .english ? "\(type), \(joined)" : "\(type) \(joined)"
    }

    private var light: String { language == .english ? "light" : "leve" }

    private func typeWord(_ type: String) -> String {
        switch (type, language) {
        case ("White", .english): "a white"
        case ("White", .portuguese): "um branco"
        case ("Rosé", .english): "a rosé"
        case ("Rosé", .portuguese): "um rosé"
        case ("Sparkling", .english): "a sparkling wine"
        case ("Sparkling", .portuguese): "um espumante"
        case ("Fortified", .english): "a fortified wine"
        case ("Fortified", .portuguese): "um fortificado"
        case (_, .english): "a red"
        case (_, .portuguese): "um tinto"
        }
    }

    private func trait(_ axis: PalateAxis) -> String {
        switch (axis, language) {
        case (.acidity, .english): "fresh"
        case (.acidity, .portuguese): "fresco"
        case (.body, .english): "full-bodied"
        case (.body, .portuguese): "encorpado"
        case (.tannin, .english): "with firm tannin"
        case (.tannin, .portuguese): "com taninos firmes"
        case (.spice, .english): "spicy"
        case (.spice, .portuguese): "especiado"
        case (.oak, .english): "oaky"
        case (.oak, .portuguese): "amadeirado"
        case (.sweetness, .english): "sweet"
        case (.sweetness, .portuguese): "doce"
        case (.fruit, .english): "fruity"
        case (.fruit, .portuguese): "frutado"
        case (.floral, _): "floral"
        }
    }
}
