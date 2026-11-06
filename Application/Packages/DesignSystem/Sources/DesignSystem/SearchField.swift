import SwiftUI

/// A search bar on the glass: a frosted capsule, the same glass as the Home cards, with a magnifier, a clear button once there is text,
/// and "Cancel" beside it while the search is in use. Lists show it once they are scrolled (CELLAR-R11).
public struct SearchField: View {
    @Binding var text: String
    var prompt: String
    var isFocused: FocusState<Bool>.Binding
    var onCancel: () -> Void
    var showsCancelButton: Bool
    /// Below 1 the glass lets more of the page through, where it would read too white.
    var glassOpacity: Double

    public init(text: Binding<String>, prompt: String, isFocused: FocusState<Bool>.Binding, glassOpacity: Double = 1, showsCancelButton: Bool = true,
                onCancel: @escaping () -> Void) {
        _text = text
        self.prompt = prompt
        self.isFocused = isFocused
        self.glassOpacity = glassOpacity
        self.showsCancelButton = showsCancelButton
        self.onCancel = onCancel
    }

    private var isActive: Bool { isFocused.wrappedValue || !text.isEmpty }

    public var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .light))
                    .opacity(0.6)
                TextField("", text: $text, prompt: Text(prompt).foregroundStyle(UVVAColor.creamFill.opacity(0.4)))
                    .font(UVVAFont.sans(14))
                    .tint(UVVAColor.creamFill)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused(isFocused)
                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .opacity(0.5)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear search", bundle: .module))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .frame(height: 40)
            .background { FrostedGlass(radius: 20).opacity(glassOpacity) }
            .contentShape(Capsule())
            .onTapGesture { isFocused.wrappedValue = true }

            if isActive && showsCancelButton {
                Button {
                    text = ""
                    isFocused.wrappedValue = false
                    onCancel()
                } label: {
                    Text("Cancel", bundle: .module)
                        .font(UVVAFont.sans(13))
                        .opacity(0.8)
                        .frame(minHeight: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .animation(.smooth(duration: 0.25), value: isActive)
    }
}
