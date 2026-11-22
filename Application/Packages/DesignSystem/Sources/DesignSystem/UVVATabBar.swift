import SwiftUI

/// The floating glass tab bar from the design system (TabBar): text only, no icons.
/// The active tab is a brighter glass capsule with cream text in 400; the others are cream in 300.
public struct UVVATabBar: View {
    @Binding var active: AppTab
    /// Tabs with something new behind them: a small dot beside the name (You, for an unread notification).
    var marked: Set<AppTab>

    public init(active: Binding<AppTab>, marked: Set<AppTab> = []) {
        _active = active
        self.marked = marked
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isActive = tab == active
                Button { active = tab } label: {
                    Text(tab.localizedTitle)
                        .font(UVVAFont.sans(11.5, isActive ? .regular : .light))
                        .tracking(0.66)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(isActive ? UVVAColor.cream : UVVAColor.cream.opacity(0.72))
                        .overlay(alignment: .topTrailing) {
                            if marked.contains(tab) {
                                Circle()
                                    .fill(UVVAColor.cream)
                                    .frame(width: 4, height: 4)
                                    .offset(x: 6, y: -1)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.easeOut(duration: 0.2), value: marked.contains(tab))
                        .padding(.horizontal, 4)
                        .frame(minWidth: 61, minHeight: 30)
                        .background {
                            if isActive {
                                Capsule()
                                    .fill(LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.1)],
                                                         startPoint: .top, endPoint: .bottom))
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
                                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
                .accessibilityValue(marked.contains(tab) ? String(localized: "New", bundle: .module) : "")
                .spotlightAnchor(tab.spotlightID)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 5)
        .background {
            // A touch brighter than the cards: a faint white veil over the same glass.
            FrostedGlass(radius: 21, dense: true)
                .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(.white.opacity(0.07)))
        }
    }
}

#Preview {
    @Previewable @State var tab = AppTab.cellar
    ZStack {
        UVVAColor.moss.ignoresSafeArea()
        UVVATabBar(active: $tab)
    }
}
