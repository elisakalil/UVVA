import Foundation

/// The toast at the top of the Summary: how one of ten languages says "cheers" (LEARN-R19).
struct Toast: Equatable {
    var word: String
    var language: String

    static let all: [Toast] = [
        Toast(word: "Santé", language: String(localized: "French", bundle: .module)),
        Toast(word: "Salud", language: String(localized: "Spanish", bundle: .module)),
        Toast(word: "Cin cin", language: String(localized: "Italian", bundle: .module)),
        Toast(word: "Saúde", language: String(localized: "Portuguese", bundle: .module)),
        Toast(word: "Prost", language: String(localized: "German", bundle: .module)),
        Toast(word: "Proost", language: String(localized: "Dutch", bundle: .module)),
        Toast(word: "Sláinte", language: String(localized: "Irish", bundle: .module)),
        Toast(word: "Yamas", language: String(localized: "Greek", bundle: .module)),
        Toast(word: "Kanpai", language: String(localized: "Japanese", bundle: .module)),
        Toast(word: "Na zdrowie", language: String(localized: "Polish", bundle: .module))
    ]
}
