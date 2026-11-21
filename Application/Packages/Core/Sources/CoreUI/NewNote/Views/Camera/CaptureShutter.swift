#if os(iOS)
import DesignSystem
import SwiftUI

/// The shutter of the label camera (CELLAR-R16, R17), in the shape of what it does: a white disc takes the front
/// photo, a red dot starts recording the back label, and a red square stops it, its ring filling as lines are read.
/// Once the count stops growing, the square beats: it is time to stop.
struct CaptureShutter: View {
    enum Mode { case photo, record, recording }

    var mode: Mode
    /// How far the recording has got, 0 to 1.
    var progress: Double
    var isSettled: Bool
    var isBusy: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(UVVAColor.creamFill.opacity(mode == .recording ? 0.25 : 1), lineWidth: 1.5)
            Circle()
                .inset(by: 1.5)
                .trim(from: 0, to: mode == .recording ? max(0.02, progress) : 0)
                .stroke(NotePalette.record, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: progress)
            RoundedRectangle(cornerRadius: mode == .recording ? 7 : 29)
                .fill(mode == .photo ? UVVAColor.creamFill : NotePalette.record)
                .frame(width: side, height: side)
                .phaseAnimator([1.0, 1.16]) { inner, scale in
                    inner.scaleEffect(isSettled && mode == .recording ? scale : 1)
                } animation: { _ in .easeInOut(duration: 0.5) }
                .opacity(isBusy ? 0.5 : 1)
        }
        .frame(width: 72, height: 72)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: mode)
        .contentShape(Circle())
    }

    private var side: CGFloat {
        switch mode {
        case .photo: 58
        case .record: 50
        case .recording: 26
        }
    }
}

/// "REC 0:04" at the top of the frame while the back label is recorded, its dot beating.
struct CaptureRecordingBadge: View {
    var start: Date
    var text: String

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(start))
            let beat = (sin(elapsed * .pi * 1.6) + 1) / 2
            HStack(spacing: 6) {
                Circle()
                    .fill(NotePalette.record)
                    .frame(width: 7, height: 7)
                    .opacity(0.3 + 0.7 * beat)
                Text(text).font(UVVAFont.sans(9, .semibold)).tracking(2.3)
                Text(Duration.seconds(Int(elapsed)).formatted(.time(pattern: .minuteSecond)))
                    .font(UVVAFont.sans(10))
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(NotePalette.cameraGround.opacity(0.6), in: Capsule())
        }
    }
}

/// A wine bottle in outline, its label a band across the body: what turns in front of the camera on the back label.
struct CaptureBottle: View {
    var body: some View {
        ZStack {
            CaptureBottleShape().stroke(UVVAColor.creamFill, lineWidth: 1)
            GeometryReader { proxy in
                let size = proxy.size
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(UVVAColor.creamFill.opacity(0.85))
                    .frame(width: size.width - 5, height: size.height * 0.24)
                    .position(x: size.width / 2, y: size.height * 0.66)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A Bordeaux bottle: a narrow neck, round shoulders, a straight body.
struct CaptureBottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width, height = rect.height
        let neck = width * 0.32
        let neckLeft = rect.midX - neck / 2, neckRight = rect.midX + neck / 2
        let shoulderTop = rect.minY + height * 0.3, shoulderBottom = rect.minY + height * 0.42
        var path = Path()
        path.move(to: CGPoint(x: neckLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: neckRight, y: rect.minY))
        path.addLine(to: CGPoint(x: neckRight, y: shoulderTop))
        path.addCurve(to: CGPoint(x: rect.maxX, y: shoulderBottom),
                      control1: CGPoint(x: neckRight, y: shoulderTop + height * 0.06),
                      control2: CGPoint(x: rect.maxX, y: shoulderTop + height * 0.05))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 2))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - 2, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 2), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: shoulderBottom))
        path.addCurve(to: CGPoint(x: neckLeft, y: shoulderTop),
                      control1: CGPoint(x: rect.minX, y: shoulderTop + height * 0.05),
                      control2: CGPoint(x: neckLeft, y: shoulderTop + height * 0.06))
        path.closeSubpath()
        return path
    }
}

/// A line of light that sweeps the frame up and down: the camera is reading what is inside it.
struct CaptureScanSweep: View {
    var color: Color

    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { proxy in
                let time = context.date.timeIntervalSinceReferenceDate
                let y = proxy.size.height * (sin(time * .pi / 1.4) + 1) / 2
                LinearGradient(colors: [color.opacity(0), color.opacity(0.28), color.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(width: proxy.size.width, height: 80)
                    .position(x: proxy.size.width / 2, y: y)
                Rectangle()
                    .fill(color)
                    .frame(width: proxy.size.width, height: 1.5)
                    .shadow(color: color, radius: 6)
                    .position(x: proxy.size.width / 2, y: y)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .allowsHitTesting(false)
    }
}

/// The four steps of the reading as icons on a line (CELLAR-R17): each lights up as it starts and takes a tick as it
/// ends, with what it is doing underneath.
struct CaptureReadingStages: View {
    var stage: LabelReadStage?
    var isDone: Bool
    var resources: NewNoteResourcesUIModel

    private var current: LabelReadStage { stage ?? .text }
    private var caption: String { isDone ? resources.readingDoneText : resources.readingStageText(stage) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                ForEach(LabelReadStage.allCases, id: \.self) { step in
                    let isPast = isDone || step < current
                    let isNow = !isDone && step == current
                    if step != .text {
                        Rectangle()
                            .fill(UVVAColor.creamFill.opacity(isPast || isNow ? 0.6 : 0.16))
                            .frame(height: 0.75)
                    }
                    Image(systemName: isPast ? "checkmark" : resources.readingStageIcon(step))
                        .font(.system(size: 14, weight: .light))
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.pulse, isActive: isNow)
                        .frame(width: 38, height: 38)
                        .background(UVVAColor.creamFill.opacity(isNow ? 0.16 : 0), in: Circle())
                        .overlay {
                            Circle().strokeBorder(UVVAColor.creamFill.opacity(isPast || isNow ? 0.7 : 0.22),
                                                  lineWidth: 0.75)
                        }
                        .opacity(isPast || isNow ? 1 : 0.4)
                }
            }
            Text(caption.uppercased())
                .font(UVVAFont.sans(9))
                .tracking(2.3)
                .opacity(0.75)
                .id(caption)
                .transition(.push(from: .bottom).combined(with: .opacity))
        }
        .animation(.easeOut(duration: 0.3), value: stage)
        .animation(.easeOut(duration: 0.3), value: isDone)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
#endif
