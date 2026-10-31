import DesignSystem
import SwiftUI

/// The phone keypad of the canvas: 1–9 with their letters, a "+*#" key that does nothing, 0 and ⌫ (ONB-R04).
struct PhoneKeypad: View {
    var onDigit: (Character) -> Void
    var onDelete: () -> Void
    @State private var presses = 0

    private static let keys: [(String, String)] = [
        ("1", ""), ("2", "ABC"), ("3", "DEF"), ("4", "GHI"), ("5", "JKL"), ("6", "MNO"),
        ("7", "PQRS"), ("8", "TUV"), ("9", "WXYZ"), ("+*#", ""), ("0", "+"), ("⌫", "")
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(Self.keys, id: \.0) { key, letters in
                Button { press(key) } label: {
                    VStack(spacing: 3) {
                        Text(key).font(UVVAFont.sans(24))
                        if !letters.isEmpty {
                            Text(letters).font(UVVAFont.sans(8.5, .medium)).tracking(1.9).opacity(0.85)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 7)
                        .fill(UVVAColor.creamFill.opacity(key.first?.isNumber == true ? 0.14 : 0)))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(key == "+*#")
                .accessibilityLabel(key == "⌫" ? Text("Delete", bundle: .module) : Text(verbatim: key))
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
                .fill(Color(hex: 0x161B11).opacity(0.72))
                .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
                .overlay(alignment: .top) { Rectangle().fill(UVVAColor.creamFill.opacity(0.12)).frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        }
        .sensoryFeedback(.selection, trigger: presses)
    }

    private func press(_ key: String) {
        presses += 1
        if key == "⌫" { onDelete() } else if key.count == 1, let digit = key.first { onDigit(digit) }
    }
}
