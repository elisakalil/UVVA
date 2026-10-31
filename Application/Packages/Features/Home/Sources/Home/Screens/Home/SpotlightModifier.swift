import DesignSystem
import SwiftUI

/// Publishes a card's frame for the tour when it has an id.
struct SpotlightModifier: ViewModifier {
    var id: String?

    func body(content: Content) -> some View {
        if let id { content.spotlightAnchor(id) } else { content }
    }
}
