import DesignSystem
import SwiftUI

/// The Splash animation: the seven grape bunches, one after the other, every 180 ms (ONB-R01).
/// One still bunch when Reduce Motion is on.
public struct GrapeLoop: View {
    public static let frameDuration = 0.18
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        TimelineView(.periodic(from: .now, by: Self.frameDuration)) { context in
            let frame = reduceMotion ? 0
                : Int(context.date.timeIntervalSinceReferenceDate / Self.frameDuration) % UVVAIllustration.grapeCount
            UVVAIllustration.grape(frame + 1)
                .resizable()
                .scaledToFit()
                .foregroundStyle(UVVAColor.creamFill)
        }
        .accessibilityHidden(true)
    }
}
