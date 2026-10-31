import DesignSystem
import SwiftUI

/// The A–Z bar on the right edge: tapping a letter jumps to the first contact with it (ONB-R37).
struct AlphabetIndex: View {
    var letters: [String]
    var onPick: (String) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(letters, id: \.self) { letter in
                Button { onPick(letter) } label: {
                    Text(letter)
                        .font(UVVAFont.sans(8.5, .medium))
                        .opacity(0.6)
                        .frame(width: 16, height: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityHidden(true)
    }
}
