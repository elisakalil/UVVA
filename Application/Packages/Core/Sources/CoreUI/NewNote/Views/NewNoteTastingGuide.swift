#if os(iOS)
import Core
import DesignSystem
import SwiftUI
import UIKit

enum TastingGuideCopy {
    static let title = String(localized: "Tasting guide", bundle: .module)
    enum Section: CaseIterable {
        case nose, palate, finish

        var title: String {
            switch self {
            case .nose: String(localized: "At the nose", bundle: .module)
            case .palate: String(localized: "On the palate", bundle: .module)
            case .finish: String(localized: "In the finish", bundle: .module)
            }
        }

        var axes: [PalateAxis] {
            switch self {
            case .nose: [.floral, .fruit]
            case .palate: [.body, .tannin, .sweetness, .acidity]
            case .finish: [.spice, .oak]
            }
        }
    }

    static func tip(_ axis: PalateAxis) -> String {
        switch axis {
        case .floral:
            String(localized: "Floral intensity goes from a hint of violet to a whole flower shop.", bundle: .module)
        case .fruit:
            String(localized: "Fruit intensity goes from a hint of apple to a whole bowl of berries, so check what you smell against what you taste.", bundle: .module)
        case .body:
            String(localized: "Body is the weight of the sip, from light like water to mouth-filling like whole milk.", bundle: .module)
        case .tannin:
            String(localized: "Tannin is the grip you feel on your gums, from a slight tug to the dry feel of strong black tea.", bundle: .module)
        case .sweetness:
            String(localized: "Sweetness is the sugar you taste on the sip, from dry to dessert-wine sweet, even if the aroma already smells like ripe peaches.", bundle: .module)
        case .acidity:
            String(localized: "Acidity is how much your mouth waters after the sip, from a little tingle to a full-on lemon face.", bundle: .module)
        case .spice:
            String(localized: "Spice shows up as the sip fades, from a pinch of pepper or cinnamon to the whole spice rack.", bundle: .module)
        case .oak:
            String(localized: "In the finish, oak can leave a hint of vanilla or toast or linger like a whole woodshop.", bundle: .module)
        }
    }
}

struct NewNoteTastingGuide: View {
    @State private var headerFade = 0.0

    var body: some View {
        VStack(spacing: 0) {
            heading(TastingGuideCopy.title, size: 24)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 26)
            .padding(.top, 28)

            ScrollView {
                VStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 40) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                heading(String(localized: "Swirl. Sniff. Sip.", bundle: .module), size: 34)
                                Spacer(minLength: 4)
                                illustration("TastingGuideWineGlass", width: 108, height: 138)
                            }
                            paragraph(String(localized: "Swirl the glass gently and smell. Take a small sip, let it coat your mouth, then notice what lingers. You can spit it out. The wine won’t take it personally.", bundle: .module))
                        }
                        scale
                        ForEach(TastingGuideCopy.Section.allCases, id: \.self) { section in
                            VStack(alignment: .leading, spacing: 26) {
                                HStack(spacing: 12) {
                                    heading(section.title, size: 29)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    sectionIllustration(section)
                                }
                                ForEach(section.axes, id: \.self) { axis in
                                    paragraph(TastingGuideCopy.tip(axis))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 12)
                    .frame(maxWidth: 540)
                    .frame(maxWidth: .infinity)

                    footerIllustration
                }
            }
            .onScrollGeometryChange(for: Double.self) { geometry in
                min(1, max(0, (geometry.contentOffset.y + geometry.contentInsets.top) / 24))
            } action: { _, opacity in
                headerFade = opacity
            }
            .overlay(alignment: .top) {
                LinearGradient(colors: [UVVAColor.parchment, UVVAColor.parchment.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 24)
                    .opacity(headerFade)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .foregroundStyle(UVVAColor.mossDeep)
        .presentationBackground(UVVAColor.parchment)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var footerIllustration: some View {
        // Crop the transparent strip at the right so the arm outlines meet the screen edge.
        let visibleWidth = 0.94
        return GeometryReader { geometry in
            illustration("TastingGuideSharing", width: geometry.size.width / visibleWidth, ink: .black)
        }
        .aspectRatio(808 * visibleWidth / 538, contentMode: .fit)
        .clipped()
    }

    @ViewBuilder
    private func illustration(_ name: String, width: CGFloat? = 76, height: CGFloat? = nil, ink: Color? = nil) -> some View {
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .renderingMode(ink == nil ? .original : .template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(ink ?? UVVAColor.mossDeep)
                .frame(width: width, height: height)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func sectionIllustration(_ section: TastingGuideCopy.Section) -> some View {
        switch section {
        case .nose:
            illustration("TastingGuideNose", width: 46, height: 52)
                .rotationEffect(.degrees(-12))
        case .palate:
            Spacer(minLength: 0)
            illustration("TastingGuidePalate", width: 116, height: 82)
        case .finish:
            EmptyView()
        }
    }

    private var scale: some View {
        VStack(alignment: .leading, spacing: 7) {
            heading(String(localized: "How loud is it?", bundle: .module), size: 26)
                .frame(maxWidth: .infinity, alignment: .trailing)
            TastingDoodle(strokes: [
                [[3, 38], [16, 34], [31, 36], [49, 29], [62, 29], [67, 23]],
                [[61, 24], [67, 22], [65, 35]],
                [[5, 31], [6, 43]], [[33, 28], [35, 40]], [[59, 22], [62, 38]]
            ])
            .frame(height: 29)
            ViewThatFits(in: .horizontal) {
                HStack {
                    scaleLabel(String(localized: "Barely there", bundle: .module))
                    Spacer(minLength: 8)
                    scaleLabel(String(localized: "Easy to spot", bundle: .module))
                    Spacer(minLength: 8)
                    scaleLabel(String(localized: "Takes over", bundle: .module))
                }
                VStack(alignment: .leading) {
                    scaleLabel(String(localized: "Barely there", bundle: .module))
                    scaleLabel(String(localized: "Easy to spot", bundle: .module))
                    scaleLabel(String(localized: "Takes over", bundle: .module))
                }
            }
        }
        .padding(34)
        .overlay {
            if let url = Bundle.module.url(forResource: "TastingGuideScaleBorder", withExtension: "png"),
               let border = UIImage(contentsOfFile: url.path) {
                Image(uiImage: border)
                    .resizable()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private func heading(_ text: String, size: CGFloat) -> some View {
        Text(text).font(UVVAFont.redGrapes(size))
            .accessibilityAddTraits(.isHeader)
    }

    private func scaleLabel(_ text: String) -> some View {
        Text(text).font(UVVAFont.redGrapes(17)).fixedSize()
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(UVVAFont.redGrapes(19))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TastingDoodle: View {
    // Hand-drawn polylines on a 69-by-65 grid, scaled to fit the drawing area.
    var strokes: [[[CGFloat]]]

    var body: some View {
        Canvas { context, size in
            let path = Path { path in
                for stroke in strokes {
                    let points = stroke.map { CGPoint(x: $0[0] * size.width / 69, y: $0[1] * size.height / 65) }
                    path.addLines(points)
                }
            }
            context.stroke(path, with: .color(UVVAColor.mossDeep),
                           style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}
#endif
