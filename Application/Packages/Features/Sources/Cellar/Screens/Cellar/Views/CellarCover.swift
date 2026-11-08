import DesignSystem
import SwiftUI

/// A cover of the grid: the front label under the veil, with the tag in RedGrapes (CELLAR-R06, R09).
struct CellarCover: View {
    var model: CellarItemUIModel

    var body: some View {
        // The photo sits in an overlay, so filling it never widens the cover past its column.
        CellarPalette.coverGround
            .overlay {
                CellarPhoto(data: model.photo)
                    .opacity(model.isNotYet ? 0.45 : 1)
                    .saturation(model.isNotYet ? 0.4 : 1)
            }
            .overlay { CellarPalette.veil }
            .overlay {
                Text(model.tag.uppercased())
                    .font(UVVAFont.redGrapes(model.cover.size))
                    .tracking(model.cover.size * 0.04)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
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

    private var alignment: Alignment {
        switch model.cover.corner {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .trailing: .trailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }
}
