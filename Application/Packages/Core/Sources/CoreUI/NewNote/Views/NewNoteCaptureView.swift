#if os(iOS)
import Core
import DesignSystem
import PhotosUI
import SwiftUI

/// "Photograph the front", "Now scan the back label", then "Reading your label" (CELLAR-R16, R17): the camera behind
/// a label-shaped frame, the two steps, the shutter and, beside it, a photo from the library instead. On the back
/// label the shutter starts a scan: the bottle is turned in front of the camera, and a second tap ends it with the
/// photo that is kept.
struct NewNoteCaptureView: View {
    var model: NewNoteUIModel
    var onCapture: (LabelPhoto, LabelScan?) -> Void

    @State private var camera = LabelCamera()
    @State private var isTaking = false
    /// The back label is being scanned: started by the shutter, ended by it.
    @State private var isScanning = false
    /// The back label's lines the scan is sure of so far.
    @State private var scannedLines = 0
    @State private var picked: PhotosPickerItem?
    @State private var labelFrame: CGRect = .zero
    /// The camera's preview on screen, to read only what shows inside the label frame.
    @State private var previewFrame: CGRect = .zero
    @State private var progress = 0.0

    private var resources: NewNoteResourcesUIModel { model.resources }
    private var isReading: Bool { model.step == .reading }

    var body: some View {
        ZStack {
            NotePalette.cameraGround.ignoresSafeArea()
            background.ignoresSafeArea()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { previewFrame = $0 }
            dim.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.captureTitle)
                        .font(UVVAFont.sans(26, .ultraLight))
                        .tracking(-0.4)
                        .accessibilityAddTraits(.isHeader)
                    Text(captureBody)
                        .font(UVVAFont.sans(12.5))
                        .opacity(0.8)
                }
                .padding(.horizontal, 30)
                .padding(.top, 44)
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(UVVAColor.creamFill.opacity(isScanning ? 1 : 0.9), lineWidth: isScanning ? 2 : 1)
                    .phaseAnimator([false, true], trigger: isScanning) { frame, phase in
                        // While scanning, the frame breathes, so it is plain the camera is reading.
                        frame.opacity(isScanning && phase ? 0.45 : 1)
                    } animation: { _ in .easeInOut(duration: 0.9) }
                    .aspectRatio(310.0 / 430.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { labelFrame = $0 }
                    .padding(.horizontal, 40)
                    .padding(.top, 26)
                    .accessibilityHidden(true)
                steps
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                if isScanning {
                    Text((scannedLines == 0 ? resources.scanStartText : resources.scannedLinesText(scannedLines))
                        .uppercased())
                        .font(UVVAFont.sans(9))
                        .tracking(2.3)
                        .opacity(0.7)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.2), value: scannedLines)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                Spacer(minLength: 16)
                foot
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .padding(.bottom, 24)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .onAppear { camera.start() }
        .onDisappear {
            _ = camera.scanner.finish()
            camera.stop()
        }
    }

    // MARK: Scan (CELLAR-R17)

    /// The back label is scanned from the camera's video; without a camera, it is read from its photo alone.
    private var scansBack: Bool { model.step == .back && camera.isAvailable }

    /// Before the scan, how to start it; during it, what to do.
    private var captureBody: String {
        guard scansBack else { return model.captureBody }
        return isScanning ? resources.scanningBodyText : resources.backBodyText
    }

    private func beginScan() {
        guard scansBack else { return }
        scannedLines = 0
        isScanning = true
        camera.scanner.begin(label: labelFrame, preview: previewFrame) { count in scannedLines = count }
    }

    /// The scan so far, ended; nil when none was running.
    private func endScan() -> LabelScan? {
        guard isScanning else { return nil }
        isScanning = false
        return camera.scanner.finish()
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

    // MARK: Steps (CELLAR-R16)

    private var steps: some View {
        HStack(spacing: 8) {
            ForEach(model.captureSteps) { step in
                let isLit = step.isCurrent || step.isDone
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(step.number).font(UVVAFont.sans(9)).tracking(2.3)
                    Text(step.label.uppercased()).font(UVVAFont.sans(9)).tracking(2.2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if step.isDone { Image(systemName: "checkmark").font(.system(size: 9, weight: .light)) }
                }
                .opacity(isLit ? 0.92 : 0.4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(UVVAColor.creamFill.opacity(step.isCurrent ? 0.12 : 0.02), in: RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(UVVAColor.creamFill.opacity(isLit ? 0.55 : 0.2), lineWidth: 0.5)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(step.isCurrent ? .isSelected : [])
            }
        }
    }

    // MARK: Shutter and library, or reading

    @ViewBuilder private var foot: some View {
        if isReading {
            VStack(spacing: 12) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(UVVAColor.creamFill.opacity(0.2))
                        Rectangle().fill(UVVAColor.creamFill).frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 1)
                Text(resources.readingProgressText.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(2.3)
                    .opacity(0.7)
            }
            .padding(.horizontal, 40)
            .onAppear {
                progress = 0
                // The reading has no measure of its own: the line eases towards the end and waits there.
                withAnimation(.easeOut(duration: 4)) { progress = 0.9 }
            }
            .accessibilityElement(children: .combine)
        } else {
            ZStack {
                if camera.isAvailable || LabelCameraSample.isAvailable {
                    Button(action: shoot) {
                        Circle()
                            .strokeBorder(UVVAColor.creamFill, lineWidth: 1.5)
                            .frame(width: 72, height: 72)
                            .overlay {
                                // While scanning, a stop square: the next tap ends the scan.
                                RoundedRectangle(cornerRadius: isScanning ? 6 : 29)
                                    .fill(UVVAColor.creamFill)
                                    .frame(width: isScanning ? 28 : 58, height: isScanning ? 28 : 58)
                                    .opacity(isTaking ? 0.6 : 1)
                                    .animation(.easeOut(duration: 0.2), value: isScanning)
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isTaking)
                    .accessibilityLabel(isScanning ? resources.scanDoneText
                        : scansBack ? resources.scanStartButtonText : resources.shutterText)
                } else {
                    Text(resources.cameraUnavailableText).font(UVVAFont.sans(12)).opacity(0.7)
                }
                library
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
            }
        }
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

    /// On the front, the photo. On the back, the first tap starts the scan and the second ends it with the photo.
    private func shoot() {
        if scansBack, !isScanning {
            beginScan()
            return
        }
        isTaking = true
        let side: LabelSide = model.step == .back ? .back : .front
        let scan = endScan()
        Task {
            await finish(camera.isAvailable ? await camera.takePhoto() : LabelCameraSample.photo(side), scan: scan)
        }
    }

    private func finish(_ data: Data?, scan: LabelScan?) async {
        let photo: LabelPhoto? = if let data { await Task.detached { LabelCamera.prepare(data) }.value } else { nil }
        isTaking = false
        // No photo: the shutter waits for another tap, which starts a new scan on the back.
        if let photo { onCapture(photo, scan) }
    }
}
#endif
