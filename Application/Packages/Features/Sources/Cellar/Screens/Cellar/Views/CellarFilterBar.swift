import DesignSystem
import SwiftUI

/// The grid and list buttons, then the five filters, which scroll sideways (CELLAR-R06, R10).
struct CellarFilterBar: View {
    var resources: CellarResourcesUIModel
    var viewMode: CellarViewMode
    var chips: [CellarChipUIModel]
    var isEnabled: Bool
    var isFiltered: Bool
    var onViewMode: (CellarViewMode) -> Void
    var onChip: (CellarFacet) -> Void
    var onClear: () -> Void

    /// Where the chips start at rest: past the gutter, the two 30-point buttons and the gaps.
    private static let chipsInset: CGFloat = 24 + 30 + 6 + 30 + 8

    var body: some View {
        // The chips scroll the full width, under the two view buttons: no band of background beside them.
        ZStack(alignment: .leading) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(chips) { chip in
                        Button { onChip(chip.facet) } label: { chipLabel(chip) }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(chip.isActive ? .isSelected : [])
                    }
                    if isFiltered {
                        Button(action: onClear) {
                            Text(resources.clearText.uppercased())
                                .font(UVVAFont.sans(10))
                                .tracking(1.8)
                                .opacity(0.7)
                                .padding(.horizontal, 6)
                                .frame(minHeight: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, Self.chipsInset)
                .padding(.trailing, 24)
            }
            .scrollIndicators(.hidden)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.45)
            HStack(spacing: 6) {
                modeButton(.grid, icon: resources.gridIcon, label: resources.gridViewText)
                modeButton(.list, icon: resources.listIcon, label: resources.listViewText)
            }
            .padding(.leading, 24)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }

    private func modeButton(_ mode: CellarViewMode, icon: String, label: String) -> some View {
        let isOn = viewMode == mode
        return Button { onViewMode(mode) } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(isOn ? UVVAColor.mossDeep : UVVAColor.creamFill)
                .frame(width: 30, height: 30)
                .background {
                    if isOn {
                        Circle().fill(UVVAColor.creamFill)
                    } else {
                        // The page itself fills the circle: it looks like the screen, and hides the chips passing under it.
                        CellarPageCutout()
                            .clipShape(Circle())
                            .overlay { Circle().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.5) }
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func chipLabel(_ chip: CellarChipUIModel) -> some View {
        HStack(spacing: 7) {
            Text(chip.label)
                .font(UVVAFont.sans(11.5))
                .lineLimit(1)
            Image(systemName: resources.chipIcon)
                .font(.system(size: 7, weight: .regular))
                .opacity(0.8)
        }
        .foregroundStyle(chip.isActive ? UVVAColor.mossDeep : UVVAColor.creamFill)
        .padding(.horizontal, 13)
        .frame(height: 30)
        .background {
            if chip.isActive {
                Capsule().fill(UVVAColor.creamFill)
            } else {
                Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.5)
            }
        }
        .contentShape(Capsule())
    }
}
