import DesignSystem
import SwiftUI

struct HomeHeader: View {
    var greeting: String
    var hasUnread: Bool
    var scroll: HeaderScroll

    static let topPadding: CGFloat = 4
    static let logoMax: CGFloat = 76
    static let logoMin: CGFloat = 30
    static let greetingBlock: CGFloat = 16 + 19
    static let bottomPadding: CGFloat = 10
    static let fullHeight = topPadding + logoMax + greetingBlock + bottomPadding
    /// Past this offset the header no longer changes, so the scroll stops reporting to it.
    static let collapseDistance: CGFloat = 150

    private var logoProgress: CGFloat { min(1, scroll.offset / Self.collapseDistance) }
    private var greetingProgress: CGFloat { min(1, scroll.offset / 110) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text("UVVA")
                    .font(UVVAFont.whiteGrape(Self.logoMax - (Self.logoMax - Self.logoMin) * logoProgress))
                    .tracking(0.02 * Self.logoMax)
                    .foregroundStyle(UVVAColor.logoInk)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(alignment: .top, spacing: 6) {
                    Button {} label: {
                        Text("+")
                            .font(UVVAFont.sans(26, .ultraLight))
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("Scan a label")
                    .spotlightAnchor(HomeSpotlightModel.scan)
                    Button {} label: {
                        BellIcon()
                            .stroke(UVVAColor.cream, style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                            .frame(width: 19, height: 19)
                            .frame(width: 34, height: 34)
                            .overlay(alignment: .topTrailing) {
                                if hasUnread {
                                    Circle().fill(UVVAColor.cream).frame(width: 3, height: 3)
                                        .padding(.top, 5).padding(.trailing, 6)
                                }
                            }
                    }
                    .accessibilityLabel(hasUnread ? "Notifications, unread" : "Notifications")
                }
                .buttonStyle(.plain)
                .foregroundStyle(UVVAColor.cream)
            }

            Text(greeting)
                .font(UVVAFont.sans(12.5, .ultraLight))
                .tracking(0.28)
                .foregroundStyle(UVVAColor.cream.opacity(0.9))
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
