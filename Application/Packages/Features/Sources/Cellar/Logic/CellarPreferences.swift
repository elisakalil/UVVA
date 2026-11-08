import Foundation

/// `CellarPreferencesProtocol` on `UserDefaults`.
@MainActor
public final class CellarPreferences: CellarPreferencesProtocol {
    static let viewModeKey = "cellar.viewMode"
    static let bannerViewsKey = "cellar.bannerViews"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The grid until the user picks the list (CELLAR-R07).
    public var viewMode: CellarViewMode {
        get { defaults.string(forKey: Self.viewModeKey).flatMap(CellarViewMode.init(rawValue:)) ?? .grid }
        set { defaults.set(newValue.rawValue, forKey: Self.viewModeKey) }
    }

    public var bannerViews: Int {
        get { defaults.integer(forKey: Self.bannerViewsKey) }
        set { defaults.set(newValue, forKey: Self.bannerViewsKey) }
    }
}
