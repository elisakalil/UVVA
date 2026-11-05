import DesignSystem
import SwiftUI

/// The map (QUIZ-R14 to R18).
struct QuizResultView: View {
    var resources = QuizResourcesUIModel()
    var model: QuizResultUIModel
    var onKeep: () -> Void
    var onReadAgain: () -> Void
    var onBack: () -> Void

    @State private var footerHeight: CGFloat = 0
    /// The clear top of the footer, where its shade fades in over the page.
    static let footerFade: CGFloat = 70
    /// Room between the last card and the button once the page is scrolled to the end.
    static let endGap: CGFloat = 24

    var body: some View {
        ZStack(alignment: .bottom) {
            QuizBackground(photoOpacity: 0.7, shade: [0.38, 0.85])
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FlowTopBar(caption: resources.palateMapText, onBack: onBack)

                    Group {
                        Text(resources.yourTasteIsText.uppercased())
                            .font(UVVAFont.sans(9))
                            .tracking(2.7)
                            .opacity(0.5)
                        Text(model.dominantPhrase.keepingDotsAtLineEnd)
                            .font(UVVAFont.sans(30, .ultraLight))
                            .tracking(-0.6)
                            .frame(maxWidth: 300, alignment: .leading)
                            .padding(.top, 7)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 44)

                    PalateMapChart(map: model.map, strong: model.highlighted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                    Text(model.caption)
                        .font(UVVAFont.sans(13, .regular))
                        .lineSpacing(5)
                        .opacity(0.8)
                        .padding(.top, 24)

                    SectionTitle(resources.yourReadingsText)
                        .padding(.top, 64)
                    VStack(spacing: 0) {
                        ForEach(Array(model.readings.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { Rectangle().opacity(0.09).frame(height: 1) }
                            QuizReadingRow(row: row)
                        }
                    }
                    .padding(.top, 18)

                    SectionTitle(resources.whereTheMapPointsText)
                        .padding(.top, 40)
                    Text(model.narrative)
                        .font(UVVAFont.sans(14.5))
                        .lineSpacing(9)
                        .opacity(0.78)
                        .padding(.top, 16)

                    MapKeepsMovingCard(resources: resources, )
                        .padding(.top, 64)
                }
                .padding(.horizontal, 26)
                .padding(.top, 8)
                // Ends just above the button, whatever the footer holds (the save error adds a line).
                .padding(.bottom, max(0, footerHeight - Self.footerFade) + Self.endGap)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeFade()

            VStack(spacing: 10) {
                if model.failedToSave {
                    Text(resources.theMapCouldNotBeText)
                        .font(UVVAFont.sans(11))
                        .opacity(0.8)
                }
                ActionButton(resources.keepThisMapText, isEnabled: !model.isSaving,
                             action: onKeep)
                TextAction(resources.readItAgainText, opacity: 0.4, action: onReadAgain)
            }
            .padding(.horizontal, 26)
            .padding(.top, Self.footerFade)
            .padding(.bottom, 18)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
            .background {
                LinearGradient(stops: [.init(color: UVVAColor.moss.opacity(0), location: 0),
                                       .init(color: UVVAColor.moss.opacity(0.72), location: 0.46),
                                       .init(color: UVVAColor.moss.opacity(0.96), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
        }
    }
}
