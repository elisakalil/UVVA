import CoreGraphics
import Observation

/// How far the Home has scrolled. Only the header reads it, so the cards are not redrawn on every frame of the scroll.
@MainActor @Observable
final class HeaderScrollModel {
    var offset: CGFloat = 0
}
