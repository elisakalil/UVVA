import SwiftUI

/// The vineyard photo (bg1) behind full pages.
/// The Quiz and the Onboarding show it softer: faded and blurred. The You tab shows only the hills (bg2).
public struct PageBackground: View {
    var photo: Image
    var photoOpacity: Double
    var blur: CGFloat
    var veiled: Bool

    /// The light veil over the photo on the You tab: darker towards the bottom, so the cream text reads.
    static let veil = LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.35), Color(hex: 0x181E12).opacity(0.55)],
                                     startPoint: .top, endPoint: .bottom)

    public init(photo: Image = UVVAPhoto.background, photoOpacity: Double = 1, blur: CGFloat = 0, veiled: Bool = false) {
        self.photo = photo
        self.photoOpacity = photoOpacity
        self.blur = blur
        self.veiled = veiled
    }

    public var body: some View {
        (photoOpacity < 1 ? UVVAColor.moss : Color.clear)
            .overlay {
                photo
                    .resizable()
                    .scaledToFill()
                    .opacity(photoOpacity)
                    .blur(radius: blur, opaque: true)
            }
            .overlay { if veiled { Self.veil } }
            .clipped()
            .ignoresSafeArea()
    }
}
