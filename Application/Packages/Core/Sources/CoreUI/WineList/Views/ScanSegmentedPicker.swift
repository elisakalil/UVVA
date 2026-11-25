#if os(iOS)
import DesignSystem
import SwiftUI

/// Two choices in a pill of glass, the chosen one in cream sliding under its word (WINELIST-R01): "Label · Wine
/// list" on the scan, "English · Português" on the line for the waiter.
struct ScanSegmentedPicker: View {
    struct Option: Identifiable, Equatable {
        var id: String
        var text: String
        var icon: String?
    }

    var options: [Option]
    var selection: String
    var onSelect: (String) -> Void

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                let isSelected = option.id == selection
                Button {
                    guard !isSelected else { return }
                    withAnimation(.spring(duration: 0.4, bounce: 0.22)) { onSelect(option.id) }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = option.icon {
                            Image(systemName: icon).font(.system(size: 11, weight: isSelected ? .regular : .light))
                        }
                        Text(option.text)
                            .font(UVVAFont.sans(11.5, isSelected ? .regular : .light))
                            .tracking(0.7)
                    }
                    .foregroundStyle(isSelected ? UVVAColor.ink : UVVAColor.creamFill)
                    .padding(.horizontal, 16)
                    .frame(minWidth: 92, minHeight: 32)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(UVVAColor.creamFill.opacity(0.92))
                                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.white.opacity(0.1)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.26), lineWidth: 0.5))
        }
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
#endif
