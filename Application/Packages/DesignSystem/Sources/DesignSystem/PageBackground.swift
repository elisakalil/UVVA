import SwiftUI

/// The vineyard photo (bg1) behind full pages, with moss while it loads.
/// The Quiz and the Onboarding show it softer: faded and blurred.
public struct PageBackground: View {
    var photoOpacity: Double
    var blur: CGFloat

    public init(photoOpacity: Double = 1, blur: CGFloat = 0) {
        self.photoOpacity = photoOpacity
        self.blur = blur
    }

    public var body: some View {
        UVVAColor.moss
            .overlay {
                UVVAPhoto.background
                    .resizable()
                    .scaledToFill()
                    .opacity(photoOpacity)
                    .blur(radius: blur, opaque: true)
            }
            .clipped()
            .ignoresSafeArea()
    }
}
