import Foundation

/// What the Cellar keeps on this device only (ARCHITECTURE §2.1, `UserDefaults`).
@MainActor
public protocol CellarPreferencesProtocol: AnyObject {
    /// The view the Cellar opens with (CELLAR-R07).
    var viewMode: CellarViewMode { get set }
    /// How many times the Cellar has shown its banner.
    var bannerViews: Int { get set }
}
