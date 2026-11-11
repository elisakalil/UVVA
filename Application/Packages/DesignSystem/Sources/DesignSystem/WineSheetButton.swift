import SwiftUI

public struct WineSheetQuestion: View {
    public var text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        Text(text)
            .font(UVVAFont.sans(17))
            .tracking(-0.17)
            .fixedSize(horizontal: false, vertical: true)
    }
}

public struct WineSheetButton: View {
    public enum Style { case choice, filled, outlined }

    var title: String
    var style: Style
    var isSelected: Bool
    var action: () -> Void

    public init(title: String, style: Style, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isSelected = isSelected
        self.action = action
    }

    private var filled: Bool { style == .filled || isSelected }

    public var body: some View {
        Button(action: action) {
            Text(style == .choice ? title.uppercased() : title)
                .font(style == .choice ? UVVAFont.redGrapes(17) : UVVAFont.sans(12.5, .medium))
                .tracking(style == .choice ? 0.7 : 0)
                .foregroundStyle(filled ? UVVAColor.creamFill : UVVAColor.mossDeep)
                .frame(maxWidth: .infinity, minHeight: style == .choice ? 47 : 45)
                .background { if filled { Capsule().fill(UVVAColor.mossDeep) } }
                .overlay { if !filled { Capsule().strokeBorder(UVVAColor.mossDeep.opacity(0.5), lineWidth: 0.5) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
