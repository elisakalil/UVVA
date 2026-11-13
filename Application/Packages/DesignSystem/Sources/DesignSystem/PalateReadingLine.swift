import SwiftUI
import UIKit

/// An axis with ten pips, lit up to its position on the Quiz bar, and its word (QUIZ-R05, R16).
/// Used by You › Map, by a friend's palate (FRI-R11), by the wine sheet and by the notes of the Cellar.
/// With `onPick`, the pips spread across the line and are set by a tap or a slide along it, like a slider.
public struct PalateReadingLine: View {
    var name: String
    var level: Int
    var word: String?
    var isStrong: Bool
    var isCompact: Bool
    var onPick: ((Int) -> Void)?

    static let count = 10

    /// `isCompact` draws the axis in small caps, under the eyebrows of a note rather than as the page's own list.
    public init(name: String, level: Int, word: String? = nil, isStrong: Bool, isCompact: Bool = false,
                onPick: ((Int) -> Void)? = nil) {
        self.name = name
        self.level = level
        self.word = word
        self.isStrong = isStrong
        self.isCompact = isCompact
        self.onPick = onPick
    }

    public var body: some View {
        HStack(spacing: 14) {
            Text(name.uppercased())
                .font(UVVAFont.sans(isCompact ? 9.5 : 11.5, .regular))
                .tracking(isCompact ? 1.7 : 1.8)
                .opacity(isCompact ? 0.84 : isStrong ? 1 : 0.62)
                .frame(width: isCompact ? 80 : 92, alignment: .leading)
            // On a note the pips spread along a line, set or only read; elsewhere they sit close together.
            if isCompact || onPick != nil {
                EditablePips(level: level, onPick: onPick)
            } else {
                HStack(spacing: 5) {
                    ForEach(0..<Self.count, id: \.self) { index in pip(index, size: 4) }
                }
            }
            if let word {
                Text(word)
                    .font(UVVAFont.sans(10.5))
                    .tracking(1)
                    .opacity(0.82)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        // A spread line is already 44 tall.
        .padding(.vertical, isCompact || onPick != nil ? 0 : 12)
        .accessibilityElement(children: onPick == nil ? .combine : .ignore)
        .modifier(AdjustableReading(name: name, level: level, onPick: onPick))
    }

    private func pip(_ index: Int, size: CGFloat) -> some View {
        Pip(isLit: index <= level, isStrong: isStrong, size: size)
    }
}

private struct Pip: View {
    var isLit: Bool
    var isStrong: Bool
    var size: CGFloat

    var body: some View {
        if isLit {
            Circle().opacity(isStrong ? 0.92 : 0.7).frame(width: size, height: size)
        } else {
            Circle().strokeBorder(lineWidth: 0.5).opacity(0.3).frame(width: size, height: size)
        }
    }
}

/// The pips of an editable line: spread across its width over a hairline, set where the finger lands or slides.
private struct EditablePips: View {
    var level: Int
    /// Nil on a saved note: the line only reads, and its pip does not glow.
    var onPick: ((Int) -> Void)?

    private func pick(at x: CGFloat, width: CGFloat) {
        let slot = width / CGFloat(PalateReadingLine.count)
        let index = min(max(Int(x / slot), 0), PalateReadingLine.count - 1)
        if index != level { onPick?(index) }
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                // The line the pips sit on, so the row reads as something to slide along: from the centre of the
                // first pip to the centre of the last, with no loose ends.
                Rectangle().frame(height: 0.5).opacity(0.22)
                    .padding(.horizontal, width / CGFloat(PalateReadingLine.count) / 2)
                HStack(spacing: 0) {
                    ForEach(0..<PalateReadingLine.count, id: \.self) { index in
                        Group {
                            if index == level && onPick != nil {
                                GlowingPip()
                            } else if index == level {
                                Pip(isLit: true, isStrong: true, size: 6)
                            } else {
                                Pip(isLit: index < level, isStrong: true, size: 5)
                                    .background { if index > level { Circle().fill(UVVAColor.parchment) } }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(width: width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { pick(at: $0.location.x, width: width) }, isEnabled: onPick != nil)
            // A slide that starts sideways sets the line; one that starts up or down is left to the page's scroll.
            .gesture(SidewaysPan(isEnabled: onPick != nil) { pick(at: $0, width: width) })
        }
        .frame(height: 44)
        .animation(.snappy(duration: 0.18), value: level)
        .sensoryFeedback(.selection, trigger: level)
    }
}

/// The pip the line stands at: the same size as the others, with a glow that breathes, as the current step of a
/// lesson does (LEARN-R13).
private struct GlowingPip: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBright = false

    var body: some View {
        Circle()
            .frame(width: 6, height: 6)
            // The glow in the line's own ink, which a shadow colour would not follow.
            .background {
                Circle()
                    .frame(width: 14, height: 14)
                    .blur(radius: isBright ? 4 : 2.5)
                    .opacity(isBright ? 0.55 : 0.15)
            }
            .onAppear {
                guard !reduceMotion else { isBright = true; return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { isBright = true }
            }
    }
}

/// A pan that only begins when the finger first moves sideways, so a line in a scroll view can be slid along without
/// taking the vertical scroll from the page (a SwiftUI drag there holds every touch that starts on it).
private struct SidewaysPan: UIGestureRecognizerRepresentable {
    /// Off on a line that only reads: every touch goes to the page.
    var isEnabled = true
    var onChange: (CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        pan.isEnabled = isEnabled
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard recognizer.state == .began || recognizer.state == .changed else { return }
        onChange(context.converter.localLocation.x)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}

/// VoiceOver reads an editable line as an adjustable value: swipe up or down to change it.
private struct AdjustableReading: ViewModifier {
    var name: String
    var level: Int
    var onPick: ((Int) -> Void)?

    func body(content: Content) -> some View {
        if let onPick {
            content
                .accessibilityLabel(name)
                .accessibilityValue("\(level + 1) of \(PalateReadingLine.count)")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: if level < PalateReadingLine.count - 1 { onPick(level + 1) }
                    case .decrement: if level > 0 { onPick(level - 1) }
                    @unknown default: break
                    }
                }
        } else {
            content
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var level = 6
    VStack(alignment: .leading, spacing: 0) {
        PalateReadingLine(name: "Acidity", level: 8, isStrong: true)
        PalateReadingLine(name: "Body", level: level, isStrong: true, isCompact: true) { level = $0 }
        PalateReadingLine(name: "Sweetness", level: 2, isStrong: true, isCompact: true) { _ in }
    }
    .padding(26)
    .foregroundStyle(UVVAColor.mossDeep)
    .background(UVVAColor.parchment)
}
#endif
