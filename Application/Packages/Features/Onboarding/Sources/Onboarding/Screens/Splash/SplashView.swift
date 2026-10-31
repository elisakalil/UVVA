import DesignSystem
import SwiftUI

/// Every launch starts here (ONB-R01): the grape bunches over the green, no text.
public struct SplashView: View {
    public init() {}

    public var body: some View {
        ZStack {
            PageBackground(photoOpacity: 0.5)
            GrapeLoop().frame(width: 140, height: 196)
        }
    }
}
