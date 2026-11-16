import SwiftUI

/// A hairline ring and a light "i", as beside the Learn title: the mark of a section that opens an `InfoSheet`.
public struct InfoMark: View {
    var size: CGFloat

    public init(size: CGFloat = 20) {
        self.size = size
    }

    public var body: some View {
        Text(verbatim: "i")
            .font(UVVAFont.sans(size * 0.65, .thin))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(lineWidth: 0.75))
            .opacity(0.82)
            .accessibilityHidden(true)
    }
}

/// A short explanation that rises over the page, with the hills behind it: a title in Red Grapes and a paragraph.
/// No close button: it leaves with a drag down or a tap outside it.
public struct InfoSheet: View {
    var title: String
    var text: String

    public init(title: String, text: String) {
        self.title = title
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(UVVAFont.redGrapes(16))
                .tracking(0.64)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .font(UVVAFont.sans(14))
                .lineSpacing(6)
                .opacity(0.86)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 30)
        .padding(.top, 36)
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground { PageBackground(photo: UVVAPhoto.hills, veiled: true) }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
