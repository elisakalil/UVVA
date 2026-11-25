import DesignSystem
import SwiftUI

/// A cover of the grid: the front label under the veil, with the tag in RedGrapes (CELLAR-R06, R09).
struct CellarCover: View {
    var model: CellarItemUIModel
    var photo: UIImage?

    var body: some View {
        // The photo sits in an overlay, so filling it never widens the cover past its column.
        CellarPalette.coverGround
            .overlay {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    UVVAPhoto.background.resizable().scaledToFill()
                }
            }
            .overlay { CellarPalette.coverVeil }
            .overlay {
                // The match and the name always close the cover at the lower left;
                // the tag takes whatever space they leave above, so the two never overlap.
                VStack(alignment: .leading, spacing: 6) {
                    tag.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: tagAlignment)
                    caption.frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
            }
            .frame(height: 200)
            .clipped()
            // `clipped()` cuts what shows, not what is tappable: the cover takes taps only within its own frame.
            .contentShape(Rectangle())
            .overlay(alignment: .trailing) { CellarPalette.rule.frame(width: 1) }
            .overlay(alignment: .bottom) { CellarPalette.rule.frame(height: 1) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
    }

    /// The match, large ("82%"), over the name, on as many lines as it needs: never cut short with "…".
    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !model.percent.isEmpty {
                Text(model.percent)
                    .font(UVVAFont.sans(26, .light))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            Text(model.name)
                .font(UVVAFont.sans(13))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
    }

    /// The tag in RedGrapes, at the size of its cover; it shrinks rather than crowd the caption.
    private var tag: some View {
        Text(model.tag.uppercased())
            .font(UVVAFont.redGrapes(model.cover.size))
            .tracking(model.cover.size * 0.04)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
    }

    /// Where the tag sits within the space above the caption.
    private var tagAlignment: Alignment {
        switch model.cover.placement {
        case .topLeading: .topLeading
        case .top: .top
        case .topTrailing: .topTrailing
        case .center: .center
        case .trailing: .trailing
        case .bottomTrailing: .bottomTrailing
        }
    }
}
