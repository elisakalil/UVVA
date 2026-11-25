import Foundation

/// How long the wine rested in wood (CELLAR-R23): read on the label or chosen by hand. It sets the map's Oak axis.
public enum OakAging: String, CaseIterable, Codable, Sendable {
    case none
    case upToSix = "upTo6"
    case sixToTwelve = "6to12"
    case twelveToTwentyFour = "12to24"
    case overTwentyFour = "over24"

    /// The months a label prints, "12 meses em barrica" → 6 to 12.
    public init(months: Int) {
        switch months {
        case ...0: self = .none
        case 1...6: self = .upToSix
        case 7...12: self = .sixToTwelve
        case 13...24: self = .twelveToTwentyFour
        default: self = .overTwentyFour
        }
    }

    /// The map's Oak axis, 0…9, for this much time in wood.
    public var oakIntensity: Double {
        switch self {
        case .none: 0.5
        case .upToSix: 3
        case .sixToTwelve: 5
        case .twelveToTwentyFour: 6.5
        case .overTwentyFour: 8
        }
    }
}

/// The woods a wine rests in, as the catalog writes them (CELLAR-R23).
public enum OakWood {
    public static let all = [
        "French oak", "American oak", "Hungarian oak", "Portuguese oak", "Slavonian oak", "Caucasian oak",
        "Chestnut", "Acacia"
    ]

    /// Folded phrase → the wood, as labels write it in the languages UVVA reads.
    static let phrases: [(phrase: String, wood: String)] = [
        ("carvalho frances", "French oak"), ("french oak", "French oak"), ("chene francais", "French oak"),
        ("rovere francese", "French oak"), ("roble frances", "French oak"), ("franzosischer eiche", "French oak"),
        ("franzosische eiche", "French oak"),
        ("carvalho americano", "American oak"), ("american oak", "American oak"), ("chene americain", "American oak"),
        ("rovere americano", "American oak"), ("roble americano", "American oak"),
        ("amerikanischer eiche", "American oak"), ("amerikanische eiche", "American oak"),
        ("carvalho hungaro", "Hungarian oak"), ("hungarian oak", "Hungarian oak"), ("chene hongrois", "Hungarian oak"),
        ("rovere ungherese", "Hungarian oak"), ("roble hungaro", "Hungarian oak"),
        ("carvalho portugues", "Portuguese oak"), ("portuguese oak", "Portuguese oak"),
        ("rovere di slavonia", "Slavonian oak"), ("slavonian oak", "Slavonian oak"),
        ("carvalho do caucaso", "Caucasian oak"), ("caucasian oak", "Caucasian oak"),
        ("castanho", "Chestnut"), ("chestnut", "Chestnut"), ("castagno", "Chestnut"), ("chataignier", "Chestnut"),
        ("acacia", "Acacia")
    ]
}
