import SwiftUI
import UIKit

/// The Splash animation: the seven grape bunches, one after the other, every 180 ms (ONB-R01).
/// One still bunch when Reduce Motion is on.
///
/// The frames change in a Core Animation keyframe animation, which the render server plays on its own: once it is
/// set up, a busy main thread no longer holds a bunch on screen longer than the others. The frames are decoded off
/// the main thread, once, and shared by every loop (`GrapeFrames`).
public struct GrapeLoop: View {
    public static let frameDuration = 0.18
    public static let cycleDuration = frameDuration * Double(UVVAIllustration.grapeCount)
    private let startsAtFirstFrame: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(startsAtFirstFrame: Bool = false) { self.startsAtFirstFrame = startsAtFirstFrame }

    public var body: some View {
        Group {
            if reduceMotion {
                UVVAIllustration.grape(1)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(UVVAColor.creamFill)
            } else {
                GrapeLayerView(startsAtFirstFrame: startsAtFirstFrame)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The seven bunches, decoded and ready to draw.
@MainActor
public enum GrapeFrames {
    private static var frames: [CGImage]?
    private static var loading: Task<[CGImage], Never>?

    /// The frames if they are already decoded.
    static var ready: [CGImage]? { frames }

    /// Decodes the frames off the main thread; the first caller starts it, the others wait for the same work.
    @discardableResult
    public static func prepare() async -> [CGImage] {
        if let frames { return frames }
        let task = loading ?? Task.detached(priority: .userInitiated) {
            (1...UVVAIllustration.grapeCount).compactMap { number in
                UIImage(named: "Grape\(number)", in: .module, with: nil)?.preparingForDisplay()?.cgImage
            }
        }
        loading = task
        let decoded = await task.value
        frames = decoded
        loading = nil
        return decoded
    }
}

private struct GrapeLayerView: UIViewRepresentable {
    let startsAtFirstFrame: Bool

    func makeUIView(context: Context) -> GrapeLayerUIView {
        GrapeLayerUIView(startsAtFirstFrame: startsAtFirstFrame)
    }

    func updateUIView(_ view: GrapeLayerUIView, context: Context) {}
}

/// A cream layer cut out by the grape: the mask's contents are the frames, so the bunch is drawn in cream like the
/// template image it replaces.
final class GrapeLayerUIView: UIView {
    private static let animationKey = "grapes"
    private let grape = CALayer()
    private let startsAtFirstFrame: Bool
    /// When this loop started, for a loop that starts at the first bunch.
    private let startedAt = CACurrentMediaTime()
    private var frames: [CGImage]?

    init(startsAtFirstFrame: Bool) {
        self.startsAtFirstFrame = startsAtFirstFrame
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.backgroundColor = UIColor(UVVAColor.creamFill).cgColor
        grape.contentsGravity = .resizeAspect
        layer.mask = grape

        if let ready = GrapeFrames.ready {
            show(ready)
        } else {
            Task { [weak self] in
                let decoded = await GrapeFrames.prepare()
                self?.show(decoded)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        grape.frame = bounds
        grape.contentsScale = window?.screen.scale ?? traitCollection.displayScale
        CATransaction.commit()
    }

    /// UIKit drops layer animations when a view leaves the window; put it back when it returns.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startAnimating() }
    }

    private func show(_ decoded: [CGImage]) {
        guard !decoded.isEmpty else { return }
        frames = decoded
        startAnimating()
    }

    private func startAnimating() {
        guard let frames, grape.animation(forKey: Self.animationKey) == nil else { return }
        let count = frames.count
        let cycle = GrapeLoop.frameDuration * Double(count)
        let now = CACurrentMediaTime()
        // Every loop on screen shows the same bunch at the same time, unless it starts at the first one.
        let elapsed = startsAtFirstFrame ? now - startedAt : Date.timeIntervalSinceReferenceDate
        let phase = elapsed.truncatingRemainder(dividingBy: cycle)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        grape.contents = frames[Int(phase / GrapeLoop.frameDuration) % count]
        CATransaction.commit()

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = frames
        animation.calculationMode = .discrete
        // Discrete keyframes take one more key time than values: each bunch holds for one frame duration.
        animation.keyTimes = (0...count).map { NSNumber(value: Double($0) / Double(count)) }
        animation.duration = cycle
        animation.repeatCount = .infinity
        animation.timeOffset = phase
        animation.isRemovedOnCompletion = false
        grape.add(animation, forKey: Self.animationKey)
    }
}
