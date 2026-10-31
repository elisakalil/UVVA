import DesignSystem
import SwiftUI

/// A row of a Settings panel: label on the left, value on the right.
struct SettingsRow<Value: View>: View {
    var label: String
    var isFirst: Bool
    var action: (() -> Void)?
    var value: Value

    init(_ label: String, isFirst: Bool = false, action: (() -> Void)? = nil, @ViewBuilder value: () -> Value) {
        self.label = label
        self.isFirst = isFirst
        self.action = action
        self.value = value()
    }

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 14) {
                Text(label).font(UVVAFont.sans(14)).opacity(0.9)
                Spacer(minLength: 8)
                value
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .overlay(alignment: .top) { if !isFirst { Rectangle().opacity(0.14).frame(height: 0.5) } }
    }
}

extension SettingsRow where Value == SettingsValue {
    init(_ label: String, value: String, isFirst: Bool = false, action: (() -> Void)? = nil) {
        self.init(label, isFirst: isFirst, action: action) { SettingsValue(text: value) }
    }
}

struct SettingsValue: View {
    var text: String

    var body: some View {
        Text(text).font(UVVAFont.sans(12)).tracking(0.5).opacity(0.86).lineLimit(1)
    }
}
