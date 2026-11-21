import SwiftUI

/// How a filled pill looks while it cannot be used: no fill, a faint ring and faded words,
/// all in the colour the fill would have had, so it stays readable on its page.
public enum DisabledPill {
    /// The opacity of the title.
    public static let textOpacity: Double = 0.5
    /// The opacity of the ring.
    public static let ringOpacity: Double = 0.3
}
