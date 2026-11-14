import CoreUI
import DesignSystem
import SwiftUI

/// The front and back labels in black and white, the tag on the front (CELLAR-R26).
struct NoteCover: View {
    var front: Data?
    var back: Data?
    var tag: String?
    var frontPreview: UIImage?
    var isReading: Bool

    var body: some View {
        GeometryReader { proxy in
            let both = front != nil && back != nil
            let frontWidth = both ? (proxy.size.width - 8) * 0.6 : proxy.size.width
            HStack(spacing: 8) {
                if front != nil || back == nil {
                    photo(front, preview: frontPreview, isReading: isReading)
                        .frame(width: frontWidth)
                        .overlay(alignment: .topLeading) { tagLabel }
                }
                if let back {
                    photo(back)
                        .frame(width: both ? proxy.size.width - 8 - frontWidth : proxy.size.width)
                        .overlay(alignment: .topLeading) { if front == nil { tagLabel } }
                }
            }
        }
        .frame(height: 196)
    }

    private func photo(_ data: Data?, preview: UIImage? = nil, isReading: Bool = false) -> some View {
        NotePalette.photoGround
            // The labels in black and white; the vineyard of a wine without photos keeps its colour.
            .overlay {
                if let data {
                    CellarPhoto(data: data, preview: preview).grayscale(1).contrast(1.08)
                } else if let preview, isReading {
                    Image(uiImage: preview).resizable().scaledToFill().grayscale(1).contrast(1.08)
                } else if isReading {
                    GrapeLoop().frame(width: 30, height: 42)
                } else {
                    UVVAPhoto.background.resizable().scaledToFill()
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    @ViewBuilder private var tagLabel: some View {
        if let tag {
            Text(tag.uppercased())
                .font(UVVAFont.redGrapes(40))
                .tracking(2.4)
                .foregroundStyle(NotePalette.tag)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background {
                    RadialGradient(colors: [Color(hex: 0x0E130A).opacity(0.72), .clear],
                                   center: .topLeading, startRadius: 0, endRadius: 180)
                }
                .allowsHitTesting(false)
        }
    }
}
