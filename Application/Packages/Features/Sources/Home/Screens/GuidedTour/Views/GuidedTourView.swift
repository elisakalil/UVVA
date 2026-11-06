import DesignSystem
import SwiftUI

public struct GuidedTourView<ViewModel: GuidedTourViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    var frames: [String: CGRect]

    public init(viewModel: ViewModel, frames: [String: CGRect]) {
        self.viewModel = viewModel
        self.frames = frames
    }

    private func spot(in size: CGSize) -> (rect: CGRect, radius: CGFloat)? {
        guard let step = viewModel.uiModel.current else { return nil }
        guard let frame = frames[step.target] ?? step.fallback.flatMap({ frames[$0] }) else { return nil }
        let padded = frame.insetBy(dx: -step.padding, dy: -step.padding)
        let top = max(padded.minY, 12)
        let bottom = min(padded.maxY, size.height - 12)
        guard bottom > top, padded.width.isFinite, padded.width > 0 else { return nil }
        return (CGRect(x: padded.minX, y: top, width: padded.width, height: bottom - top), step.cornerRadius)
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let spot = spot(in: size)
            ZStack(alignment: .topLeading) {
                ZStack {
                    Color(hex: 0x0E130A).opacity(viewModel.uiModel.step == 0 ? 0.90 : 0.74)
                    if let spot {
                        RoundedRectangle(cornerRadius: spot.radius, style: .continuous)
                            .frame(width: spot.rect.width, height: spot.rect.height)
                            .position(x: spot.rect.midX, y: spot.rect.midY)
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
                .contentShape(Rectangle())
                .onTapGesture {}

                if let spot {
                    RoundedRectangle(cornerRadius: spot.radius, style: .continuous)
                        .strokeBorder(.white.opacity(0.34), lineWidth: 0.5)
                        .background(RoundedRectangle(cornerRadius: spot.radius, style: .continuous)
                            .fill(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.03), .white.opacity(0.06)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .shadow(color: Color(hex: 0x0A0E08).opacity(0.4), radius: 15, y: 12)
                        .frame(width: spot.rect.width, height: spot.rect.height)
                        .position(x: spot.rect.midX, y: spot.rect.midY)
                        .allowsHitTesting(false)
                }

                if viewModel.uiModel.step == 0 {
                    TourIntro(uiModel: viewModel.uiModel)
                        .padding(.horizontal, 30)
                        .offset(y: size.height * 0.34)
                        .transition(.opacity)
                }

                TourCard(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .frame(width: size.width)
                    .position(x: size.width / 2, y: cardCenterY(spot: spot?.rect, in: size))
                    .id(viewModel.uiModel.step)
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: spot?.rect)
            .animation(.easeOut(duration: 0.3), value: viewModel.uiModel.step)
        }
        .ignoresSafeArea()
        .foregroundStyle(UVVAColor.mossDeep)
    }

    private func cardCenterY(spot: CGRect?, in size: CGSize) -> CGFloat {
        let half = TourCard<ViewModel>.estimatedHeight / 2
        guard let spot else { return size.height - 44 - half - 20 }
        if spot.height > size.height / 2 { return 60 + half }
        if spot.midY < size.height / 2 {
            return min(spot.maxY + 20 + half, size.height - 40 - half)
        }
        return max(spot.minY - 20 - half, 60 + half)
    }
}

#Preview {
    GuidedTourView(viewModel: MockGuidedTourViewModel(), frames: [:])
}
