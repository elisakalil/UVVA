import SwiftUI

/// Wine-stained paper shared by the certificate gallery, card and share preview.
public struct CertificateBackground: View {
    private var dimmed: Bool

    public init(dimmed: Bool = false) {
        self.dimmed = dimmed
    }

    public var body: some View {
        GeometryReader { geometry in
            Color(hex: 0x521D27)
                .overlay {
                    Image("CertificateTexture", bundle: .module)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blendMode(.luminosity)
                        .opacity(0.48)
                }
                .overlay(Color.black.opacity(dimmed ? 0.65 : 0.08))
                .overlay {
                    LinearGradient(colors: [.black.opacity(0.12), .clear, .black.opacity(0.2)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                .clipped()
        }
    }
}
