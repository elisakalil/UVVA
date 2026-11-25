import Foundation

/// The language the line for the waiter is written in (WINELIST-R08): the restaurant's, not the phone's.
enum WineListLanguage: String, CaseIterable, Identifiable {
    case english, portuguese

    var id: Self { self }

    /// The phone's, to start with.
    static var initial: Self {
        Bundle.main.preferredLocalizations.first?.hasPrefix("pt") == true ? .portuguese : .english
    }

    /// Written in its own language, as a language picker shows it.
    var name: String {
        switch self {
        case .english: "English"
        case .portuguese: "Português"
        }
    }
}
