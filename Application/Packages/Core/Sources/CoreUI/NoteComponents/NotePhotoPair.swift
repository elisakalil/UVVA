#if os(iOS)
import SwiftUI

public struct NotePhotoPair<Front: View, Back: View>: View {
    private let front: Front
    private let back: Back

    public init(@ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self.front = front()
        self.back = back()
    }

    public var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(0, proxy.size.width - 8)
            HStack(spacing: 8) {
                front.frame(width: availableWidth * 0.6)
                back.frame(width: availableWidth * 0.4)
            }
        }
        .frame(height: 220)
    }
}
#endif
