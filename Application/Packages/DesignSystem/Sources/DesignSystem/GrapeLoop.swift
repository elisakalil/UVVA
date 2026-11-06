import SwiftUI

/// The Splash animation: the seven grape bunches, one after the other, every 180 ms (ONB-R01).
/// One still bunch when Reduce Motion is on.
public struct GrapeLoop: View {
    public static let frameDuration = 0.18
    public static let cycleDuration = frameDuration * Double(UVVAIllustration.grapeCount)
    @State private var startedAt = Date()
    private let startsAtFirstFrame: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(startsAtFirstFrame: Bool = false) { self.startsAtFirstFrame = startsAtFirstFrame }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: Self.frameDuration)) { context in
            let frame = reduceMotion ? 0
                : max(0, Int((startsAtFirstFrame ? context.date.timeIntervalSince(startedAt) : context.date.timeIntervalSinceReferenceDate) / Self.frameDuration)) % UVVAIllustration.grapeCount
            UVVAIllustration.grape(frame + 1)
                .resizable()
                .scaledToFit()
                .foregroundStyle(UVVAColor.creamFill)
        }
        .onAppear { startedAt = .now }
        .accessibilityHidden(true)
    }
}
