import SwiftUI
import UIKit

/// The person's photo in a circle; without one, the cream figure over the vineyard (YOU-R01).
public struct Avatar: View {
    var photo: Data?
    var size: CGFloat

    public init(photo: Data?, size: CGFloat = 56) {
        self.photo = photo
        self.size = size
    }

    public var body: some View {
        ZStack {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color(hex: 0x5E7A80)
                UVVAPhoto.background.resizable().scaledToFill().scaleEffect(1.8, anchor: UnitPoint(x: 0.3, y: 0.22))
                Image("Avatar", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.72, height: size * 0.72)
                    .offset(y: size * 0.14)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
