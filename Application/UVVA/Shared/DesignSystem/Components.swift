import SwiftUI

/// Title of a group of cards, sitting on the photo above them (APRENDER, PALAVRA DO DIA).
struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .semibold))
            .tracking(3.6)
            .foregroundStyle(UVVAColor.cream84)
            .padding(.top, 22)
    }
}

/// Small tracked caption under a title (NAVARRA, SPAIN).
struct Caption: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8, .semibold))
            .tracking(2.6)
            .foregroundStyle(UVVAColor.cream60)
    }
}

/// Full-width pill button. Filled is the cream main action; outline is the quiet one beside it.
struct PillButton<Label: View>: View {
    enum Style { case filled, outline }

    var style: Style = .filled
    var action: () -> Void
    @ViewBuilder var label: Label

    var body: some View {
        Button(action: action) {
            label
                .font(UVVAFont.sans(14, .regular))
                .foregroundStyle(style == .filled ? UVVAColor.ink : UVVAColor.cream)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if style == .filled {
                        Capsule().fill(UVVAColor.creamFill)
                    } else {
                        Capsule().strokeBorder(UVVAColor.cream.opacity(0.4), lineWidth: 0.75)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Selectable chip of the "Choose your wine" filters.
/// Selected: cream with ink text. Idle: a faint glass outline with cream text.
struct Chip: View {
    var text: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(UVVAFont.sans(13, isSelected ? .medium : .regular))
                .tracking(0.6)
                .lineLimit(1)
                .foregroundStyle(isSelected ? UVVAColor.ink : UVVAColor.cream84)
                .padding(.horizontal, 13)
                .frame(minHeight: 30)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient(colors: [UVVAColor.creamFill, UVVAColor.creamFill.opacity(0.88)],
                                                 startPoint: .top, endPoint: .bottom))
                            .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.04))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.75))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Intensity of one axis as six dots: filled up to the value, small rings after it.
struct IntensityDots: View {
    var value: Double
    static let count = 6

    private var filled: Int { Int((value / PalateMap.range.upperBound * Double(Self.count)).rounded()) }

    var body: some View {
        HStack(spacing: 4.5) {
            ForEach(0..<Self.count, id: \.self) { index in
                if index < filled {
                    Circle().fill(UVVAColor.cream).frame(width: 3.5, height: 3.5)
                } else {
                    Circle().strokeBorder(UVVAColor.cream60, lineWidth: 0.7).frame(width: 3.5, height: 3.5)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(filled) of \(Self.count)")
    }
}

/// Wraps its children onto new lines, left-aligned, like words in a paragraph.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += isFirst ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}
