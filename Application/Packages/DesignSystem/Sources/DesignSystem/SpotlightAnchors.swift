import SwiftUI

/// Where the parts of a screen are, by id, for an overlay that points at them (the Home tour, HOME-R31).
public struct SpotlightAnchors: PreferenceKey {
    public static let defaultValue: [String: Anchor<CGRect>] = [:]

    public static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Publishes this view's frame under `id` for `overlayPreferenceValue(SpotlightAnchors.self)`.
    public func spotlightAnchor(_ id: String) -> some View {
        anchorPreference(key: SpotlightAnchors.self, value: .bounds) { [id: $0] }
    }
}
