import CoreUI
import DesignSystem
import SwiftUI

/// The front and back labels, with the verdict on the first (CELLAR-R26). Only the photos the note has: one alone
/// takes the whole width, and a note with none shows no cover (2026-11-15). While the labels are read, both places wait.
struct NoteCover: View {
    var front: Data?
    var back: Data?
    var tag: String?
    var frontPreview: UIImage?
    var isReading: Bool

    var body: some View {
        if isReading || (front != nil && back != nil) {
            NotePhotoPair {
                photo(front, preview: frontPreview, isReading: isReading)
                    .overlay(alignment: .topLeading) { tagLabel }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } back: {
                photo(back, isReading: isReading)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        } else if let only = front ?? back {
            photo(only, preview: front == nil ? nil : frontPreview)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) { tagLabel }
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func photo(_ data: Data?, preview: UIImage? = nil, isReading: Bool = false) -> some View {
        NotePalette.photoGround
            .overlay {
                if let data {
                    CellarPhoto(data: data, preview: preview)
                } else if let preview, isReading {
                    Image(uiImage: preview).resizable().scaledToFill()
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
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
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
