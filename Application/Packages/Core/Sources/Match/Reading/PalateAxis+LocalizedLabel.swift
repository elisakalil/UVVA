import Core
import Foundation

extension PalateAxis {
    public var localizedLabel: String {
        switch self {
        case .acidity: String(localized: "Acidity", bundle: .module)
        case .body: String(localized: "Body", bundle: .module)
        case .floral: String(localized: "Floral", bundle: .module)
        case .fruit: String(localized: "Fruit", bundle: .module)
        case .oak: String(localized: "Oak", bundle: .module)
        case .spice: String(localized: "Spice", bundle: .module)
        case .sweetness: String(localized: "Sweetness", bundle: .module)
        case .tannin: String(localized: "Tannin", bundle: .module)
        }
    }
}
