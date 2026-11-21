#if os(iOS)
import Core
import DesignSystem
import PhotosUI
import SwiftUI

/// The front, the back label and the reading (CELLAR-R16, R17), with as few words as possible: a bar of three steps
/// at the top, a word or two of title, and the camera behind a label-shaped frame that says the rest.
///
/// - Front: the shutter is a white disc. On the shot the screen flashes, the photo flies to a thumbnail beside the
///   shutter and the frame turns like the bottle does.
/// - Back label: the shutter becomes a red dot, to record, and the frame shows the bottle turning. While recording,
///   "REC" and its timer, a line sweeping the frame, the ring of the shutter filling with the lines read and a tick
///   for each; once the count stops growing, the stop square beats and the title says to tap it.
/// - Reading: the back photo held still under the sweeping line, and the four steps of the reading as they pass.
struct NewNoteCaptureView: View {
    var model: NewNoteUIModel
    var onCapture: (LabelPhoto, LabelScan?) -> Void

    /// Lines that fill the shutter's ring: about a whole back label.
    private static let fullScanLines = 24.0
    /// Fewer lines than this and the scan is not offered as done, however still the count is.
    private static let settledMinLines = 6

    @State private var camera = LabelCamera()
    @State private var isTaking = false
    /// The back label is being recorded: started by the shutter, ended by it.
    @State private var isScanning = false
    @State private var scanStart = Date()
    /// The back label's lines the scan is sure of so far.
    @State private var scannedLines = 0
    /// The count has stopped growing: time to stop.
    @State private var isSettled = false
    @State private var picked: PhotosPickerItem?
    @State private var labelFrame: CGRect = .zero
    /// The camera's preview on screen, to read only what shows inside the label frame.
    @State private var previewFrame: CGRect = .zero
    @State private var thumbnailFrame: CGRect = .zero
    @State private var flash = 0.0
    @State private var shots = 0
    /// The frame's turn from the front to the back label, in degrees.
    @State private var turn = 0.0
    /// The front photo on its way from the frame to its thumbnail.
    @State private var flying: FlyingPhoto?
    @State private var readingProgress = 0.0
    #if DEBUG
    /// Without a camera (the simulator), a recording that counts lines on its own, to see it.
    @State private var sampleScan: Task<Void, Never>?
    #endif

    private var resources: NewNoteResourcesUIModel { model.resources }
    private var isReading: Bool { model.step == .reading }
    private var scanProgress: Double { min(1, Double(scannedLines) / Self.fullScanLines) }

    var body: some View {
        ZStack {
            NotePalette.cameraGround.ignoresSafeArea()
            background.ignoresSafeArea()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { previewFrame = $0 }
            dim.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                progressBar
                    .padding(.horizontal, 30)
                    .padding(.top, 28)
                Text(title)
                    .font(UVVAFont.sans(26, .ultraLight))
                    .tracking(-0.4)
                    .id(title)
                    .transition(.push(from: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 30)
                    .padding(.top, 22)
                    .accessibilityAddTraits(.isHeader)
                labelWindow
                    .padding(.horizontal, 40)
                    .padding(.top, 22)
                status
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                Spacer(minLength: 8)
                foot
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .padding(.bottom, 24)
            }
            .animation(.easeOut(duration: 0.3), value: title)
            flyingLayer
            Color.white.opacity(flash).ignoresSafeArea().allowsHitTesting(false)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: shots)
        .sensoryFeedback(trigger: isScanning) { _, scanning in scanning ? .start : .stop }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: scannedLines / 2)
        .sensoryFeedback(.success, trigger: isSettled) { _, settled in settled }
        .sensoryFeedback(.success, trigger: model.isReadingDone) { _, done in done }
        .onAppear { camera.start() }
        .onDisappear {
            _ = endScan()
            camera.stop()
        }
        .onChange(of: model.step) { old, new in stepChanged(from: old, to: new) }
        .onChange(of: model.readingStage) { _, stage in advanceReading(to: stage) }
        .onChange(of: model.isReadingDone) { _, done in
            guard done else { return }
            withAnimation(.easeOut(duration: 0.3)) { readingProgress = 1 }
        }
        .task(id: isScanning ? scannedLines : -1) { await waitForSettle() }
    }

    private var title: String {
        guard isScanning else { return model.captureTitle }
        return isSettled ? resources.scanSettledTitleText : resources.scanningTitleText
    }

    // MARK: The three steps

    /// Front, back label, reading: done steps full, the back label filling as it is recorded, the reading as it
    /// goes.
    private var progressBar: some View {
        HStack(spacing: 6) {
            segment(model.step == .front ? 0 : 1, isCurrent: model.step == .front)
            segment(model.step == .front ? 0 : model.step == .back ? (isScanning ? scanProgress : 0) : 1,
                    isCurrent: model.step == .back)
                .animation(.easeOut(duration: 0.35), value: scannedLines)
            segment(isReading ? readingProgress : 0, isCurrent: isReading)
        }
        .frame(height: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(currentStepText)
    }

    private func segment(_ fill: Double, isCurrent: Bool) -> some View {
        Capsule()
            .fill(UVVAColor.creamFill.opacity(isCurrent ? 0.3 : 0.14))
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(UVVAColor.creamFill)
                        .frame(width: proxy.size.width * fill)
                }
            }
    }

    private var currentStepText: String {
        switch model.step {
        case .front: resources.frontStepText
        case .back: resources.backStepText
        default: resources.readingTitleText
        }
    }

    // MARK: The frame

    private var labelWindow: some View {
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(isScanning ? NotePalette.record : UVVAColor.creamFill.opacity(0.9),
                          lineWidth: isScanning ? 2 : 1)
            .rotation3DEffect(.degrees(turn), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .overlay {
                if isScanning || isReading {
                    // Over the still back photo, light as the label is, the reading sweeps in grape.
                    CaptureScanSweep(color: isScanning ? NotePalette.record : UVVAColor.grape)
                        .transition(.opacity)
                }
            }
            .overlay {
                if showsBackHint {
                    backHint.transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) {
                if isScanning {
                    CaptureRecordingBadge(start: scanStart, text: resources.recordingText)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.3), value: isScanning)
            .animation(.easeOut(duration: 0.3).delay(showsBackHint ? 0.45 : 0), value: showsBackHint)
            .aspectRatio(310.0 / 430.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { labelFrame = $0 }
    }

    /// The back label is recorded, not photographed: the bottle turning, until the shutter is tapped.
    private var showsBackHint: Bool { scansBack && !isScanning && !isTaking }

    private var backHint: some View {
        VStack(spacing: 12) {
            // The bottle turning on itself, as it should in front of the camera.
            VStack(spacing: 6) {
                CaptureBottle()
                    .frame(width: 18, height: 52)
                    .phaseAnimator([-55.0, 55.0]) { bottle, angle in
                        bottle.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                    } animation: { _ in .easeInOut(duration: 1.1) }
                Image(systemName: resources.turnIcon)
                    .font(.system(size: 13, weight: .light))
                    .opacity(0.8)
            }
            Text(resources.backHintText.uppercased())
                .font(UVVAFont.sans(9))
                .tracking(2.3)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(NotePalette.cameraGround.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    /// Under the frame, while recording, the lines read so far.
    @ViewBuilder private var status: some View {
        if isScanning {
            Text(resources.scannedLinesText(scannedLines).uppercased())
                .font(UVVAFont.sans(11))
                .tracking(2.3)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(scannedLines)))
                .animation(.easeOut(duration: 0.2), value: scannedLines)
                .opacity(scannedLines == 0 ? 0.5 : 0.9)
                .transition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    // MARK: Camera

    /// The live camera; while reading, the back photo held still. In an overlay, so a photo filling the screen
    /// never widens the page.
    private var background: some View {
        Color.clear
            .overlay {
                if let data = model.readingPhoto, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else if camera.isAvailable {
                    LabelCameraPreview(session: camera.session)
                }
            }
            .clipped()
            .allowsHitTesting(false)
    }

    /// Everything outside the label frame darkened (66%), as in the artboard.
    private var dim: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let frame = labelFrame.offsetBy(dx: -origin.x, dy: -origin.y)
            Path { path in
                path.addRect(CGRect(origin: .zero, size: proxy.size).insetBy(dx: -100, dy: -100))
                if frame != .zero { path.addRoundedRect(in: frame, cornerSize: CGSize(width: 18, height: 18)) }
            }
            .fill(NotePalette.cameraGround.opacity(0.66), style: FillStyle(eoFill: true))
        }
        .allowsHitTesting(false)
    }

    // MARK: Front to back

    private struct FlyingPhoto: Equatable {
        var image: UIImage
        var hasLanded = false
    }

    /// The front photo, from the frame to its thumbnail.
    private var flyingLayer: some View {
        GeometryReader { proxy in
            if let flying {
                let origin = proxy.frame(in: .global).origin
                let rect = (flying.hasLanded ? thumbnailFrame : labelFrame).offsetBy(dx: -origin.x, dy: -origin.y)
                Image(uiImage: flying.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: rect.width, height: rect.height)
                    .clipShape(RoundedRectangle(cornerRadius: flying.hasLanded ? 6 : 18))
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func stepChanged(from old: NewNoteStep, to new: NewNoteStep) {
        if old == .front, new == .back {
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) { turn += 180 }
            guard let data = model.photoFront, let image = UIImage(data: data) else { return }
            flying = FlyingPhoto(image: image)
            Task { @MainActor in
                // A beat in the frame first, so the photo is seen before it flies.
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.spring(duration: 0.55, bounce: 0.18)) {
                    flying?.hasLanded = true
                } completion: {
                    flying = nil
                }
            }
        }
        if new == .reading {
            readingProgress = 0
            advanceReading(to: model.readingStage)
        }
    }

    // MARK: Reading

    /// The reading's segment moves towards the end of the step it is at, slower as it gets close, so it never
    /// stands still; the next step takes it further, and the end fills it.
    private func advanceReading(to stage: LabelReadStage?) {
        guard isReading, !model.isReadingDone else { return }
        let target: Double = switch stage {
        case .text, nil: 0.35
        case .wine: 0.62
        case .catalog: 0.82
        case .pairings: 0.94
        }
        withAnimation(.easeOut(duration: 6)) { readingProgress = max(readingProgress, target) }
    }

    // MARK: Shutter and library, or reading

    @ViewBuilder private var foot: some View {
        if isReading {
            CaptureReadingStages(stage: model.readingStage, isDone: model.isReadingDone, resources: resources)
                .padding(.horizontal, 40)
                .transition(.opacity)
        } else {
            ZStack {
                if camera.isAvailable || LabelCameraSample.isAvailable {
                    Button(action: shoot) {
                        CaptureShutter(mode: shutterMode, progress: scanProgress, isSettled: isSettled,
                                       isBusy: isTaking)
                    }
                    .buttonStyle(.plain)
                    .disabled(isTaking)
                    .accessibilityLabel(isScanning ? resources.scanDoneText
                        : scansBack ? resources.scanStartButtonText : resources.shutterText)
                } else {
                    Text(resources.cameraUnavailableText).font(UVVAFont.sans(12)).opacity(0.7)
                }
                HStack {
                    library
                        .opacity(isScanning ? 0 : 1)
                        .disabled(isScanning)
                    Spacer()
                    thumbnail
                }
                .padding(.horizontal, 40)
                .animation(.easeOut(duration: 0.2), value: isScanning)
            }
        }
    }

    private var shutterMode: CaptureShutter.Mode {
        isScanning ? .recording : scansBack ? .record : .photo
    }

    /// The front photo once taken, with a tick: one of the two is done.
    private var thumbnail: some View {
        Color.clear
            .frame(width: 40, height: 54)
            .overlay {
                if model.step != .front, let data = model.photoFront, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6).strokeBorder(UVVAColor.creamFill.opacity(0.7),
                                                                           lineWidth: 0.75)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(NotePalette.cameraGround)
                                .frame(width: 16, height: 16)
                                .background(UVVAColor.creamFill, in: Circle())
                                .offset(x: 5, y: 5)
                        }
                        .opacity(flying == nil ? 1 : 0)
                        .accessibilityLabel(resources.frontStepText)
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { thumbnailFrame = $0 }
    }

    /// A photo already taken, in place of the shutter (CELLAR-R16a). The system picker needs no library access.
    private var library: some View {
        PhotosPicker(selection: $picked, matching: .images) {
            Image(systemName: resources.libraryIcon)
                .font(.system(size: 17, weight: .light))
                .frame(width: 48, height: 48)
                .overlay { Circle().strokeBorder(UVVAColor.creamFill.opacity(0.55), lineWidth: 0.5) }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isTaking)
        .accessibilityLabel(resources.libraryText)
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            choose(item)
        }
    }

    // MARK: Scan (CELLAR-R17)

    /// The back label is recorded from the camera's video; without a camera, it is read from its photo alone (in
    /// debug builds in the simulator, a recording that counts on its own stands in).
    private var scansBack: Bool { model.step == .back && (camera.isAvailable || LabelCameraSample.isAvailable) }

    private func beginScan() {
        guard scansBack else { return }
        scannedLines = 0
        isSettled = false
        scanStart = .now
        isScanning = true
        if camera.isAvailable {
            camera.scanner.begin(label: labelFrame, preview: previewFrame) { count in scannedLines = count }
        } else {
            #if DEBUG
            sampleScan = Task { @MainActor in
                for count in [1, 2, 4, 5, 7, 9, 10, 12, 13, 15, 16, 17, 18] {
                    try? await Task.sleep(for: .milliseconds(420))
                    guard !Task.isCancelled else { return }
                    scannedLines = count
                }
            }
            #endif
        }
    }

    /// The scan so far, ended; nil when none was running.
    private func endScan() -> LabelScan? {
        guard isScanning else { return nil }
        isScanning = false
        isSettled = false
        #if DEBUG
        sampleScan?.cancel()
        sampleScan = nil
        #endif
        return camera.isAvailable ? camera.scanner.finish() : nil
    }

    /// The count has not grown for a while: the label has passed.
    private func waitForSettle() async {
        guard isScanning else { return }
        if isSettled { withAnimation { isSettled = false } }
        try? await Task.sleep(for: .seconds(2.2))
        guard !Task.isCancelled, isScanning, scannedLines >= Self.settledMinLines else { return }
        withAnimation { isSettled = true }
    }

    // MARK: Taking

    /// The chosen photo, made into its two copies like one from the camera, off the main thread. A photo from the
    /// library is not of what the camera scanned: the scan is set aside.
    private func choose(_ item: PhotosPickerItem) {
        isTaking = true
        _ = endScan()
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await finish(data, scan: nil)
        }
    }

    /// On the front, the photo. On the back, the first tap starts recording and the second ends it with the photo.
    private func shoot() {
        if scansBack, !isScanning {
            beginScan()
            return
        }
        isTaking = true
        shots += 1
        withAnimation(.easeOut(duration: 0.06)) { flash = 0.8 } completion: {
            withAnimation(.easeOut(duration: 0.35)) { flash = 0 }
        }
        let side: LabelSide = model.step == .back ? .back : .front
        let scan = endScan()
        Task {
            await finish(camera.isAvailable ? await camera.takePhoto() : LabelCameraSample.photo(side), scan: scan)
        }
    }

    private func finish(_ data: Data?, scan: LabelScan?) async {
        let photo: LabelPhoto? = if let data { await Task.detached { LabelCamera.prepare(data) }.value } else { nil }
        isTaking = false
        // No photo: the shutter waits for another tap, which starts a new recording on the back.
        if let photo { onCapture(photo, scan) }
    }
}
#endif
