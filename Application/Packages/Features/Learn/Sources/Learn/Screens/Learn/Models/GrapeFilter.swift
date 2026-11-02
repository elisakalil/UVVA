import Foundation

/// LEARN-R08: All, Red, White, or one country.
enum GrapeFilter: Equatable {
    case all, red, white
    case country(String)

    var id: String {
        switch self {
        case .all: "all"
        case .red: "red"
        case .white: "white"
        case let .country(name): "country-\(name)"
        }
    }
}
