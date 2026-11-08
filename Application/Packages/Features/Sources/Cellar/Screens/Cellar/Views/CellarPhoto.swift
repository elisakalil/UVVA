import DesignSystem
import SwiftUI
import UIKit

/// The front label of a wine, filling its frame. A wine never photographed shows the Home's vineyard instead.
struct CellarPhoto: View {
    var data: Data?

    var body: some View {
        image
            // Filled past its frame, the photo would take taps meant for what sits around it.
            .allowsHitTesting(false)
    }

    @ViewBuilder private var image: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            UVVAPhoto.background
                .resizable()
                .scaledToFill()
        }
    }
}
