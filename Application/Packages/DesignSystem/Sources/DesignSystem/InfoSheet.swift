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
    public enum Style {
        /// The paragraph in sans, in a sheet of a fixed height.
        case plain
        /// Every word drawn in Red Grapes, the title much larger, and the sheet as tall as its words (You › Map).
        case handwritten
    }

    var title: String
    var text: String
    var style: Style

    /// The height of the words, for the handwritten sheet to fit them.
    @State private var contentHeight: CGFloat = 0

    private static let topPadding: CGFloat = 36
    private static let bottomPadding: CGFloat = 40

    public init(title: String, text: String, style: Style = .plain) {
        self.title = title
        self.text = Self.sentencePerLine(text)
        self.style = style
    }

    /// Every new sentence starts on a new line: the space after ".", "!", "?" or "…" becomes a line break.
    static func sentencePerLine(_ text: String) -> String {
        text.replacingOccurrences(of: #"(?<=[.!?…])\s+(?=\S)"#, with: "\n", options: .regularExpression)
    }

    public var body: some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 30)
            .padding(.top, Self.topPadding)
            .foregroundStyle(UVVAColor.creamFill)
            .presentationBackground { PageBackground(photo: UVVAPhoto.hills, veiled: true) }
            .presentationDetents([detent])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
    }

    private var detent: PresentationDetent {
        switch style {
        case .plain: .height(300)
        case .handwritten: .height(max(300, contentHeight + Self.topPadding + Self.bottomPadding))
        }
    }

    @ViewBuilder private var content: some View {
        switch style {
        case .plain:
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
        case .handwritten:
            VStack(alignment: .leading, spacing: 20) {
                Text(title.uppercased())
                    .font(UVVAFont.redGrapes(34))
                    .lineSpacing(-3)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(text.uppercased())
                    .font(UVVAFont.redGrapes(17))
                    .lineSpacing(7)
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
