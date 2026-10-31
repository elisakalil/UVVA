import DesignSystem
import SwiftUI

/// The dark layer over the Home with a window of light on the area of each step, and the cream card that
/// explains it (HOME-R30 to R33). It takes every touch, so the Home underneath does not respond.
public struct GuidedTourView: View {
    var viewModel: GuidedTourViewModel
    /// The frames published with `spotlightAnchor`, in this view's space.
    var frames: [String: CGRect]

    public init(viewModel: GuidedTourViewModel, frames: [String: CGRect]) {
        self.viewModel = viewModel
        self.frames = frames
    }

    /// The lit area, kept 12 pt inside the screen when the target is taller than it.
    private func spot(in size: CGSize) -> (rect: CGRect, radius: CGFloat)? {
        guard let step = viewModel.current else { return nil }
        guard let frame = frames[step.target] ?? step.fallback.flatMap({ frames[$0] }) else { return nil }
        let padded = frame.insetBy(dx: -step.padding, dy: -step.padding)
        // Clamped by hand: while the Home scrolls to the target it can still be off screen, and an empty
        // intersection (CGRect.null) would reach the layer as an infinite frame.
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
                    Color(hex: 0x0E130A).opacity(viewModel.tour.step == 0 ? 0.82 : 0.74)
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

                if viewModel.tour.step == 0 {
                    TourIntro(firstName: viewModel.firstName)
                        .padding(.horizontal, 30)
                        .offset(y: size.height * 0.34)
                        .transition(.opacity)
                }

                TourCard(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .frame(width: size.width)
                    .position(x: size.width / 2, y: cardCenterY(spot: spot?.rect, in: size))
                    .id(viewModel.tour.step)
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: spot?.rect)
            .animation(.easeOut(duration: 0.3), value: viewModel.tour.step)
        }
        .ignoresSafeArea()
        .foregroundStyle(UVVAColor.mossDeep)
    }

    /// The card sits below an area in the top half and above an area in the bottom half;
    /// the intro card sits at the bottom.
    private func cardCenterY(spot: CGRect?, in size: CGSize) -> CGFloat {
        let half = TourCard.estimatedHeight / 2
        guard let spot else { return size.height - 44 - half - 20 }
        // An area taller than half the screen ("Choose your wine") leaves the card at the top, over the header.
        if spot.height > size.height / 2 { return 60 + half }
        if spot.midY < size.height / 2 {
            return min(spot.maxY + 20 + half, size.height - 40 - half)
        }
        return max(spot.minY - 20 - half, 60 + half)
    }
}
