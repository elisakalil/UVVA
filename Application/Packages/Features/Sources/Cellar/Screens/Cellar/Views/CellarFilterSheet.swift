import DesignSystem
import SwiftUI

/// The values of one filter, each with its count; "Show n bottles" closes, "Any …" turns the filter off (CELLAR-R10).
struct CellarFilterSheet: View {
    var resources: CellarResourcesUIModel
    var model: CellarFilterSheetUIModel
    var onPick: (String) -> Void
    var onClose: () -> Void
    var onAny: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.title.uppercased())
                    .font(UVVAFont.redGrapes(20))
                    .tracking(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: resources.closeIcon)
                        .font(.system(size: 11, weight: .regular))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(resources.closeText)
                .padding(.trailing, -10)
            }
            .padding(.horizontal, 26)
            .padding(.top, 22)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.options.enumerated()), id: \.element.id) { index, option in
                        optionRow(option)
                            .overlay(alignment: .top) {
                                if index > 0 { UVVAColor.creamFill.opacity(0.09).frame(height: 1) }
                            }
                    }
                }
                .padding(.horizontal, 26)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 4) {
                Button(action: onClose) {
                    Text(model.showText.uppercased())
                        .font(UVVAFont.sans(9.5, .semibold))
                        .tracking(3.2)
                        .foregroundStyle(UVVAColor.mossDeep)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(UVVAColor.creamFill, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                Button(action: onAny) {
                    Text(model.anyText.uppercased())
                        .font(UVVAFont.sans(10))
                        .tracking(2)
                        .opacity(0.72)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
            .padding(.bottom, 12)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground {
            ZStack {
                PageBackground()
                CellarPalette.veil.ignoresSafeArea()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private func optionRow(_ option: CellarFilterOptionUIModel) -> some View {
        Button { onPick(option.value) } label: {
            HStack(spacing: 14) {
                Text(option.value)
                    .font(UVVAFont.sans(15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(option.count)
                    .font(UVVAFont.sans(11))
                    .tracking(0.6)
                    .opacity(0.6)
                ZStack {
                    if option.isSelected {
                        Circle().fill(UVVAColor.creamFill)
                        Image(systemName: resources.checkIcon)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(UVVAColor.mossDeep)
                    } else {
                        Circle().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.5)
                    }
                }
                .frame(width: 20, height: 20)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 2)
            .opacity(option.isDimmed ? 0.35 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(option.isSelected ? .isSelected : [])
    }
}
