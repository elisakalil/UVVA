import Foundation

/// The three tabs of You (YOU-R02).
public enum YouTab: CaseIterable, Sendable {
    case progress, map, settings

    var title: String {
        switch self {
        case .progress: String(localized: "Progress", bundle: .module)
        case .map: String(localized: "Map", bundle: .module)
        case .settings: String(localized: "Settings", bundle: .module)
        }
    }
}
