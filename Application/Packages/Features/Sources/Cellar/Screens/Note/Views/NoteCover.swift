import CoreUI
import DesignSystem
import SwiftUI

/// The front and back labels in black and white, the tag on the front (CELLAR-R26).
struct NoteCover: View {
    var front: Data?
    var back: Data?
    var tag: String?

    var body: some View {
        GeometryReader { proxy in
            let both = front != nil && back != nil
            let frontWidth = both ? (proxy.size.width - 8) * 0.6 : proxy.size.width
            HStack(spacing: 8) {
                if front != nil || back == nil {
                    photo(front)
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

    private func photo(_ data: Data?) -> some View {
        NotePalette.photoGround
            // The labels in black and white; the vineyard of a wine without photos keeps its colour.
            .overlay { CellarPhoto(data: data).grayscale(data == nil ? 0 : 1).contrast(data == nil ? 1 : 1.08) }
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
