import SwiftUI
import UIKit

/// The person's photo in a circle; without one, the default picture (YOU-R01): the cream figure over the hills of the
/// page photo, as a still crop (`DefaultAvatar`, 480 px), so no avatar loads the whole page photo to show a corner of it.
public struct Avatar: View {
    var photo: Data?
    var size: CGFloat

    public init(photo: Data?, size: CGFloat = 56) {
        self.photo = photo
        self.size = size
    }

    public var body: some View {
        Group {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("DefaultAvatar", bundle: .module).resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
