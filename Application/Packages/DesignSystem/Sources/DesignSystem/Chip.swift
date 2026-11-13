import SwiftUI

/// A capsule tag or selectable filter, over glass or paper.
public struct Chip: View {
    public enum Surface { case glass, paper }

    var text: String
    var isSelected: Bool
    var fillsWidth: Bool
    var surface: Surface
    var icon: String?
    var cutsOutSelectedLabel: Bool
    var glassTint: Color?
    var action: (() -> Void)?

    public init(text: String, isSelected: Bool = false, fillsWidth: Bool = false, surface: Surface = .glass,
                icon: String? = nil, cutsOutSelectedLabel: Bool = false, glassTint: Color? = nil,
                action: (() -> Void)? = nil) {
        self.text = text
        self.isSelected = isSelected
        self.fillsWidth = fillsWidth
        self.surface = surface
        self.icon = icon
        self.cutsOutSelectedLabel = cutsOutSelectedLabel
        self.glassTint = glassTint
        self.action = action
    }

    private var ink: Color { surface == .glass ? (glassTint ?? UVVAColor.cream84) : UVVAColor.mossDeep }
    private var selectedInk: Color { surface == .glass ? UVVAColor.ink : UVVAColor.creamFill }
    private var selectedFill: Color { surface == .glass ? (glassTint ?? UVVAColor.creamFill) : UVVAColor.mossDeep }
    private var outline: Color { surface == .glass ? .white.opacity(0.18) : ink.opacity(0.28) }
    /// On paper a chip is only its outline.
    private var restingFill: Color { surface == .glass ? .white.opacity(0.04) : .clear }

    public var body: some View {
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            label
        }
    }

    @ViewBuilder private var label: some View {
        if isSelected && cutsOutSelectedLabel {
            capsuleLabel(cutOut: true).compositingGroup()
        } else {
            capsuleLabel(cutOut: false)
        }
    }

    private func capsuleLabel(cutOut: Bool) -> some View {
        Group {
            if let icon {
                Image(systemName: icon).accessibilityLabel(text)
            } else {
                Text(text)
                    .lineLimit(fillsWidth ? nil : 1)
                    .multilineTextAlignment(.center)
            }
        }
        .font(UVVAFont.sans(13, isSelected ? .medium : .regular))
        .tracking(0.6)
        .foregroundStyle(isSelected ? selectedInk : ink)
        .blendMode(cutOut ? .destinationOut : .normal)
        .padding(.horizontal, 13)
        .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 30)
        .background {
            if isSelected {
                Capsule()
                    .fill(LinearGradient(colors: [selectedFill, selectedFill.opacity(surface == .glass && glassTint != nil ? 1 : 0.88)],
                                         startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
            } else {
                Capsule()
                    .fill(fillsWidth ? .clear : restingFill)
                    .overlay(Capsule().strokeBorder(outline, lineWidth: 0.75))
            }
        }
        .contentShape(Capsule())
    }
}
