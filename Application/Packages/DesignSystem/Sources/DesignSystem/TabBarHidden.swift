import SwiftUI

/// A tab asks for the tab bar to step aside, so its own bar can take the bottom of the screen
/// (Friends while choosing who comes to a table).
public struct TabBarHiddenKey: PreferenceKey {
    public static let defaultValue = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

public extension View {
    func tabBarHidden(_ hidden: Bool) -> some View {
        preference(key: TabBarHiddenKey.self, value: hidden)
    }
}
