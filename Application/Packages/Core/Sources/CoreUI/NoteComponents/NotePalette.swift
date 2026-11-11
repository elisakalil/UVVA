#if os(iOS)
import DesignSystem
import SwiftUI

/// The paper of the tasting note, from its artboard.
public enum NotePalette {
    public static let paper = Color(hex: 0xEFE8DA)
    public static let ink = UVVAColor.ink
    static let cameraGround = Color(hex: 0x0F130C)
    static let veil = Color(hex: 0x0E130A).opacity(0.58)
    /// Behind a label photo while it loads.
    public static let photoGround = Color(hex: 0x1C2017)
    /// The tag on the front label.
    public static let tag = Color(hex: 0xC4E2EC)
}
#endif
