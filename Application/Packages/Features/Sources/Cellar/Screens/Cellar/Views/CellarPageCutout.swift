import DesignSystem
import SwiftUI

/// The page behind the Cellar, drawn again in place: a small view filled with it looks clear,
/// yet hides what scrolls under it.
struct CellarPageCutout: View {
    @Environment(\.backdropFrame) private var page

    var body: some View {
        GeometryReader { proxy in
            if let page {
                let frame = proxy.frame(in: .global)
                // The same page as `CellarView` draws, the size of the screen, shifted so it lines up with it.
                PageBackground(blur: 2, veiled: true)
                    .frame(width: page.width, height: page.height)
                    .offset(x: page.minX - frame.minX, y: page.minY - frame.minY)
            }
        }
        .allowsHitTesting(false)
    }
}
