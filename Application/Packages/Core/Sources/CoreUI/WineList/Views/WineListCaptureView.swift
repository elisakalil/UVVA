#if os(iOS)
import DesignSystem
import PhotosUI
import SwiftUI

/// "Scan · Wine list" (WINELIST-R03): the camera behind a page-shaped frame of four corners, the shutter, and a pane
/// of glass that counts the wines found. Each photo is one page: the wines add up until "Use this list".
struct WineListCaptureView: View {
    var model: WineListUIModel
    var onCapture: (Data) -> Void
    var onUseList: () -> Void

    @State private var camera = LabelCamera()
    @State private var isTaking = false
    @State private var picked: PhotosPickerItem?
    @State private var flash = 0.0
    @State private var shots = 0

    private var resources: WineListResourcesUIModel { model.resources }
    private var isBusy: Bool { isTaking || model.isReading }

    var body: some View {
        ZStack {
            NotePalette.cameraGround.ignoresSafeArea()
            background.ignoresSafeArea()
            // A page is bright: held still while it is read, it steps back further, so the glass stays legible.
            NotePalette.cameraGround.opacity(model.readingPhoto == nil ? 0.28 : 0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.3), value: model.readingPhoto == nil)
            VStack(spacing: 16) {
                pageFrame
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                panel
                    .padding(.horizontal, 22)
                foot
                    .frame(height: 84)
                    .padding(.bottom, 12)
            }
            Color.white.opacity(flash).ignoresSafeArea().allowsHitTesting(false)
        }
        .foregroundStyle(UVVAColor.creamFill)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: shots)
        .sensoryFeedback(.success, trigger: model.wineCount) { old, new in new > old }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }

    // MARK: Camera

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

    /// Four corners where the page goes; while it is read, the grape line sweeps it.
    private var pageFrame: some View {
        PageCorners()
            .stroke(UVVAColor.creamFill, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .overlay {
                if model.isReading {
                    CaptureScanSweep(color: UVVAColor.grape)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .transition(.opacity)
                }
            }
            .overlay {
                if !model.isReading, model.wineCount == 0, !camera.isAvailable, !WineListSample.isAvailable {
                    Text(resources.cameraUnavailableText).font(UVVAFont.sans(12)).opacity(0.7)
                }
            }
            .animation(.easeOut(duration: 0.3), value: model.isReading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: The glass

    private var panel: some View {
        WineListGlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text((model.isReading ? resources.readingTitleText : resources.pageText(model.pagesRead + 1)).uppercased())
                        .font(UVVAFont.sans(10, .regular))
                        .tracking(1.8)
                    if model.isReading {
                        ReadingDots()
                    }
                }
                Text(model.captureTitle)
                    .font(UVVAFont.sans(17))
                    .contentTransition(.numericText(value: Double(model.wineCount)))
                Text(model.captureBody)
                    .font(UVVAFont.sans(12.5))
                    .lineSpacing(3)
                    .foregroundStyle(UVVAColor.creamFill.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
                if model.canUseList {
                    Button(action: onUseList) {
                        HStack {
                            Text(resources.useListText.uppercased())
                                .font(UVVAFont.sans(10, .semibold))
                                .tracking(2.6)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .light))
                        }
                        .padding(.top, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) { Rectangle().fill(UVVAColor.creamFill.opacity(0.14)).frame(height: 1) }
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.easeOut(duration: 0.3), value: model.wineCount)
            .animation(.easeOut(duration: 0.3), value: model.canUseList)
        }
    }

    // MARK: Shutter and library

    private var foot: some View {
        ZStack {
            if camera.isAvailable || WineListSample.isAvailable {
                Button(action: shoot) {
                    CaptureShutter(mode: .photo, progress: 0, isSettled: false, isBusy: isBusy)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .accessibilityLabel(resources.shutterText)
            }
            HStack {
                library
                Spacer()
                pages
            }
            .padding(.horizontal, 40)
        }
    }

    /// The pages read so far, as stacked sheets.
    private var pages: some View {
        ZStack {
            ForEach(0..<min(model.pagesRead, 3), id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(NotePalette.paper)
                    .frame(width: 30, height: 40)
                    .rotationEffect(.degrees(Double(index) * 5 - 4))
                    .offset(x: CGFloat(index) * 2, y: CGFloat(-index) * 2)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            }
            if model.pagesRead > 0 {
                Text("\(model.pagesRead)")
                    .font(UVVAFont.sans(12, .medium))
                    .foregroundStyle(NotePalette.ink)
                    .offset(x: 4, y: -4)
            }
        }
        .frame(width: 48, height: 54)
        .animation(.spring(duration: 0.4, bounce: 0.3), value: model.pagesRead)
        .accessibilityHidden(model.pagesRead == 0)
    }

    private var library: some View {
        PhotosPicker(selection: $picked, matching: .images) {
            Image(systemName: resources.libraryIcon)
                .font(.system(size: 17, weight: .light))
                .frame(width: 48, height: 48)
                .overlay { Circle().strokeBorder(UVVAColor.creamFill.opacity(0.55), lineWidth: 0.5) }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .accessibilityLabel(resources.libraryText)
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            isTaking = true
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                await finish(data)
            }
        }
    }

    private func shoot() {
        isTaking = true
        shots += 1
        withAnimation(.easeOut(duration: 0.06)) { flash = 0.8 } completion: {
            withAnimation(.easeOut(duration: 0.35)) { flash = 0 }
        }
        Task {
            await finish(camera.isAvailable ? await camera.takePhoto() : WineListSample.photo(page: model.pagesRead))
        }
    }

    /// The photo upright and at full size, the way Vision reads small print best, off the main thread.
    private func finish(_ data: Data?) async {
        let photo: LabelPhoto? = if let data { await Task.detached { LabelCamera.prepare(data) }.value } else { nil }
        isTaking = false
        if let photo { onCapture(photo.reading) }
    }
}

/// The four corners of the page frame.
private struct PageCorners: Shape {
    var arm: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: rect.minX, y: rect.minY), 1, 1), (CGPoint(x: rect.maxX, y: rect.minY), -1, 1),
            (CGPoint(x: rect.minX, y: rect.maxY), 1, -1), (CGPoint(x: rect.maxX, y: rect.maxY), -1, -1)
        ]
        for (point, dx, dy) in corners {
            path.move(to: CGPoint(x: point.x, y: point.y + arm * dy))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x + arm * dx, y: point.y))
        }
        return path
    }
}

/// Three dots that breathe while the page is read.
private struct ReadingDots: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 3, height: 3)
                    .phaseAnimator([0.25, 1.0]) { dot, opacity in dot.opacity(opacity) } animation: { _ in
                        .easeInOut(duration: 0.6).delay(Double(index) * 0.18)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
