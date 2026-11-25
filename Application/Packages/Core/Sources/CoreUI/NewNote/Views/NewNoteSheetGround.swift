#if os(iOS)
import DesignSystem
import SwiftUI

/// The ground of the chip sheets: the vineyard under the note's veil.
struct NewNoteSheetGround: View {
    var body: some View {
        ZStack {
            PageBackground()
            NotePalette.veil.ignoresSafeArea()
        }
    }
}

/// The sheet's own ground, cut to the capsule of a disabled "Add": the chips scrolling behind the button stay out
/// of it, while the foot of the sheet around it stays clear. Drawn where the sheet draws it, so the vineyard lines up.
struct NewNoteSheetGroundCapsule: View {
    @Environment(\.newNoteSheetFrame) private var sheetFrame

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            NewNoteSheetGround()
                .frame(width: sheetFrame.width, height: sheetFrame.height)
                .offset(x: sheetFrame.minX - frame.minX, y: sheetFrame.minY - frame.minY)
        }
        .clipShape(Capsule())
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension EnvironmentValues {
    /// Where the chip sheet is on screen, for `NewNoteSheetGroundCapsule`.
    @Entry var newNoteSheetFrame: CGRect = .zero
}

private struct NewNoteSheetGroundModifier: ViewModifier {
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .environment(\.newNoteSheetFrame, frame)
            .background {
                Color.clear
                    .ignoresSafeArea()
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
            }
            .presentationBackground { NewNoteSheetGround() }
    }
}

extension View {
    /// The vineyard ground of a chip sheet, and where it lies for a disabled "Add".
    func newNoteSheetGround() -> some View {
        modifier(NewNoteSheetGroundModifier())
    }
}
#endif
