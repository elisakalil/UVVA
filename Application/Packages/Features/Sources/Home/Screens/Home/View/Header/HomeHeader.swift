import DesignSystem
import SwiftUI

struct HomeHeader: View {
    var resources = HomeResourcesUIModel()
    var greeting: String
    var scroll: HeaderScrollModel
    /// The `+` (HOME-R03): the new note, the same as the Cellar's (CELLAR-R14).
    var onScan: () -> Void = {}

    /// The logo's size at full scale, measured once.
    @State private var logoSize = CGSize.zero

    static let topPadding: CGFloat = 4
    static let logoMax: CGFloat = 76
    static let logoMin: CGFloat = 30
    static let greetingBlock: CGFloat = 16 + 19
    static let bottomPadding: CGFloat = 10
    static let fullHeight = topPadding + logoMax + greetingBlock + bottomPadding
    /// Extra room between the header at full size and the first card.
    static let cardsGap: CGFloat = 16
    static let buttonSize: CGFloat = 38
    /// The `+`, the Home's one action, large at the edge (the notifications are in You).
    static let scanButtonSize: CGFloat = 50
    static let scanSymbolSize: CGFloat = 44
    /// Past this offset the header no longer changes, so the scroll stops reporting to it.
    static let collapseDistance: CGFloat = 150

    private var logoProgress: CGFloat { min(1, scroll.offset / Self.collapseDistance) }
    private var logoScale: CGFloat { 1 - (1 - Self.logoMin / Self.logoMax) * logoProgress }
    private var greetingProgress: CGFloat { min(1, scroll.offset / 110) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Set once at full size and scaled down: a new font size on every frame of the scroll made the
                // text lay out and render again each time.
                Text(resources.homeHeaderBrand)
                    .font(UVVAFont.whiteGrape(Self.logoMax))
                    .tracking(0.02 * Self.logoMax)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .fixedSize()
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { logoSize = $0 }
                    .scaleEffect(logoScale, anchor: .topLeading)
                    .frame(width: logoSize.width * logoScale, height: logoSize.height * logoScale, alignment: .topLeading)
                Spacer(minLength: 0)
                Button(action: onScan) {
                    Text(resources.homeHeaderScanSymbol)
                        .font(UVVAFont.sans(Self.scanSymbolSize, .ultraLight))
                        .frame(width: Self.scanButtonSize, height: Self.scanButtonSize)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(resources.homeHeaderScanLabel)
                .spotlightAnchor(HomeSpotlightID.scan)
                // Its stroke on the edge of the page, level with the logo.
                .padding(.trailing, -6)
                .padding(.top, -3)
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
            }

            Text(greeting)
                .font(UVVAFont.sans(12.5, .ultraLight))
                .tracking(0.28)
                .foregroundStyle(Color.white.opacity(0.9))
                .frame(maxWidth: 280, alignment: .leading)
                .padding(.top, 16)
                .frame(height: Self.greetingBlock * (1 - greetingProgress), alignment: .top)
                .clipped()
                .opacity(1 - greetingProgress)
        }
        .padding(.top, Self.topPadding)
        .padding(.horizontal, UVVASpace.inset)
        .padding(.bottom, Self.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { backdrop }
    }

    /// Once the cards scroll under the header, a light blur rises behind it: full under the status bar,
    /// then fading out quickly across the header so the cards slide into it.
    private var backdrop: some View {
        Rectangle()
            // The light material blurs fully; on its own it whitens the photo, so it is toned back down
            // and given its colour back, leaving the blur just a touch lighter than the page.
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .light)
            .brightness(Self.backdropBrightness)
            .saturation(Self.backdropSaturation)
            .mask {
                LinearGradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.55),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
            .padding(.bottom, -Self.backdropFade)
            .ignoresSafeArea(edges: .top)
            .opacity(min(1, scroll.offset / 40))
            .allowsHitTesting(false)
    }

    /// How far below the header the blur finishes fading out.
    static let backdropFade: CGFloat = 12
    /// Tone of the blur against the page: darker than the bare light material, with the photo's colour restored.
    static let backdropBrightness = -0.11
    static let backdropSaturation = 1.6
}
