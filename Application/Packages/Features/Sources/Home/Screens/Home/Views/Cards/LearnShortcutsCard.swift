import Core
import DesignSystem
import SwiftUI

/// Learn section: a tall region card with its map on the left, a grape and a lesson stacked on the right.
/// Each opens its Learn tab: By region, By grape and The path (HOME-R18, LEARN-R04).
struct LearnShortcutsCard: View {
    var onOpen: (CourseKind) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Learn")
            HStack(alignment: .top, spacing: 14) {
                FrostedCard(padding: 18) {
                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow(text: "A region")
                        Text("Uco Valley").font(UVVAFont.whiteGrape(23)).padding(.top, 10)
                        Text("Malbec at altitude").font(UVVAFont.sans(12, .regular)).foregroundStyle(UVVAColor.cream84)
                            .padding(.top, 6)
                        ArgentinaOutline()
                            .stroke(UVVAColor.cream.opacity(0.55), style: StrokeStyle(lineWidth: 0.8, lineJoin: .round))
                            .aspectRatio(0.46, contentMode: .fit)
                            .frame(maxHeight: 130)
                            .overlay(alignment: .topLeading) {
                                GeometryReader { proxy in
                                    RegionPin().position(x: proxy.size.width * 0.17, y: proxy.size.height * 0.34)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        Spacer(minLength: 0)
                        Eyebrow(text: "6 lessons")
                    }
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .contentShape(Rectangle())
                .onTapGesture { onOpen(.region) }

                VStack(spacing: 14) {
                    ShortcutCard(eyebrow: "A grape", title: "Tempranillo", subtitle: "Spain's great red", action: "6 lessons")
                        .contentShape(Rectangle())
                        .onTapGesture { onOpen(.grape) }
                    ShortcutCard(eyebrow: "A lesson", title: "Organic, biodynamic and natural",
                                 subtitle: "What the labels really mean", action: "Start")
                        .contentShape(Rectangle())
                        .onTapGesture { onOpen(.path) }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
