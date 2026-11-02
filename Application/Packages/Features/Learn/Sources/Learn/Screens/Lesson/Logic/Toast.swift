import Foundation

/// The toast at the top of the Summary: one word in one of ten languages, with what it means (LEARN-R19).
struct Toast: Equatable {
    var word: String
    var meaning: String
    var language: String

    static let all: [Toast] = [
        Toast(word: "Santé", meaning: String(localized: "health", bundle: .module), language: String(localized: "French", bundle: .module)),
        Toast(word: "Salud", meaning: String(localized: "health", bundle: .module), language: String(localized: "Spanish", bundle: .module)),
        Toast(word: "Cin cin", meaning: String(localized: "cheers", bundle: .module), language: String(localized: "Italian", bundle: .module)),
        Toast(word: "Saúde", meaning: String(localized: "health", bundle: .module), language: String(localized: "Portuguese", bundle: .module)),
        Toast(word: "Prost", meaning: String(localized: "cheers", bundle: .module), language: String(localized: "German", bundle: .module)),
        Toast(word: "Proost", meaning: String(localized: "cheers", bundle: .module), language: String(localized: "Dutch", bundle: .module)),
        Toast(word: "Sláinte", meaning: String(localized: "health", bundle: .module), language: String(localized: "Irish", bundle: .module)),
        Toast(word: "Yamas", meaning: String(localized: "to our health", bundle: .module), language: String(localized: "Greek", bundle: .module)),
        Toast(word: "Kanpai", meaning: String(localized: "empty the glass", bundle: .module), language: String(localized: "Japanese", bundle: .module)),
        Toast(word: "Na zdrowie", meaning: String(localized: "to health", bundle: .module), language: String(localized: "Polish", bundle: .module))
    ]
}
