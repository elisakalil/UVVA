import SwiftUI
import UIKit

/// The loading of a card whose content is being read again: a curtain of small grape bunches, in several sizes and
/// opacities, running slowly down the card. It fills the space it is given and fades out at its top and bottom edges;
/// the card clips it and fades it in and out. Still when Reduce Motion is on.
///
/// Drawn in one `Canvas` from the time alone (`GrapeCurtainField`), so a frame costs a few dozen small images and no
/// layout, and nothing runs once the curtain leaves the screen.
public struct GrapeCurtain: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sprites: [CGImage] = GrapeSprites.ready ?? []
    @State private var start = Date()

    public init() {}

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            GrapeCurtainFrame(time: reduceMotion ? 0 : timeline.date.timeIntervalSince(start), sprites: sprites)
        }
        .task {
            if sprites.isEmpty { sprites = await GrapeSprites.prepare() }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The curtain at one moment.
struct GrapeCurtainFrame: View {
    var time: TimeInterval
    var sprites: [CGImage]

    var body: some View {
        Canvas { context, size in
            guard !sprites.isEmpty else { return }
            // Template images, drawn in cream like every other bunch of the app.
            let images = sprites.map { sprite -> GraphicsContext.ResolvedImage in
                var image = context.resolve(Image(decorative: sprite, scale: 1).renderingMode(.template))
                image.shading = .color(UVVAColor.creamFill)
                return image
            }
            for grape in GrapeCurtainField.grapes(in: size, at: time) {
                let image = images[grape.sprite % images.count]
                let width = grape.height * image.size.width / max(image.size.height, 1)
                context.opacity = grape.opacity
                context.draw(image, in: CGRect(x: grape.center.x - width / 2, y: grape.center.y - grape.height / 2,
                                               width: width, height: grape.height))
            }
        }
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.24),
                                   .init(color: .black, location: 0.62), .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

/// Where every bunch of the curtain is at a given time. Pure: the same size and time give the same curtain.
///
/// The curtain is made of strands, one every `strandSpacing` points. A strand runs down at its own slow speed and
/// carries its bunches at its own spacing; a bunch that leaves at the bottom comes back at the top, both out of sight.
/// Each bunch has a depth: the near ones are larger and clearer, the far ones small and faint.
enum GrapeCurtainField {
    struct Grape: Equatable {
        var center: CGPoint
        var height: CGFloat
        var opacity: Double
        var sprite: Int
    }

    static let strandSpacing: CGFloat = 34
    /// How far above and below the card a bunch travels, so it never appears or disappears inside it.
    static let margin: CGFloat = 30
    /// Points per second.
    static let speed: ClosedRange<CGFloat> = 12...26
    static let gap: ClosedRange<CGFloat> = 46...78
    static let height: ClosedRange<CGFloat> = 10...26
    static let opacity: ClosedRange<Double> = 0.12...0.55
    /// How far a bunch drifts to either side as it goes down.
    static let sway: CGFloat = 2.5

    static func grapes(in size: CGSize, at time: TimeInterval) -> [Grape] {
        guard size.width > 0, size.height > 0 else { return [] }
        let strands = max(1, Int((size.width / strandSpacing).rounded()))
        let spacing = size.width / CGFloat(strands)
        var grapes: [Grape] = []
        for strand in 0..<strands {
            let x = (CGFloat(strand) + 0.5) * spacing + (unit(strand, 1) - 0.5) * spacing * 0.5
            let speed = lerp(Self.speed, unit(strand, 2))
            let gap = lerp(Self.gap, unit(strand, 3))
            let count = Int(((size.height + 2 * margin) / gap).rounded(.up))
            let cycle = CGFloat(count) * gap
            let travelled = CGFloat(time) * speed + unit(strand, 4) * cycle
            for index in 0..<count {
                let depth = unit(strand, 100 + index)
                let offset = CGFloat(index) * gap + (unit(strand, 200 + index) - 0.5) * gap * 0.4
                let y = (offset + travelled).truncatingRemainder(dividingBy: cycle) - margin
                let drift = CGFloat(sin(time * 0.5 + Double(strand) * 1.7 + Double(index) * 2.3)) * sway
                grapes.append(Grape(center: CGPoint(x: x + drift, y: y),
                                    height: lerp(Self.height, depth),
                                    opacity: opacity.lowerBound + (opacity.upperBound - opacity.lowerBound) * Double(depth),
                                    sprite: Int(unit(strand, 300 + index) * 7_000)))
            }
        }
        return grapes
    }

    private static func lerp(_ range: ClosedRange<CGFloat>, _ t: CGFloat) -> CGFloat {
        range.lowerBound + (range.upperBound - range.lowerBound) * t
    }

    /// A fixed value in 0..<1 for a strand and a slot (SplitMix64): the curtain is the same on every run.
    private static func unit(_ strand: Int, _ slot: Int) -> CGFloat {
        var z = UInt64(truncatingIfNeeded: strand) &* 0x9E37_79B9_7F4A_7C15 &+ UInt64(truncatingIfNeeded: slot) &* 0xD1B5_4A32_D192_ED03
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return CGFloat(z >> 11) / CGFloat(1 << 53)
    }
}

/// The seven bunches at the size of the curtain, decoded and ready to draw. The illustrations are several hundred
/// pixels tall; scaled down on every frame they would shimmer as they move.
@MainActor
public enum GrapeSprites {
    /// The tallest bunch of the curtain at 3x, with room to spare.
    static let pixelHeight: CGFloat = 96
    private static var sprites: [CGImage]?
    private static var loading: Task<[CGImage], Never>?

    /// The sprites if they are already made.
    static var ready: [CGImage]? { sprites }

    /// Makes the sprites off the main thread; the first caller starts it, the others wait for the same work.
    @discardableResult
    public static func prepare() async -> [CGImage] {
        if let sprites { return sprites }
        let height = pixelHeight
        let task = loading ?? Task.detached(priority: .userInitiated) {
            (1...UVVAIllustration.grapeCount).compactMap { number -> CGImage? in
                guard let image = UIImage(named: "Grape\(number)", in: .module, with: nil), image.size.height > 0 else { return nil }
                let points = height / image.scale
                return image.preparingThumbnail(of: CGSize(width: points * image.size.width / image.size.height, height: points))?.cgImage
            }
        }
        loading = task
        let made = await task.value
        sprites = made
        loading = nil
        return made
    }
}
