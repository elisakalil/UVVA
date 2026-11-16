import Core
import DesignSystem
import SwiftUI

/// Map (YOU-R09 to R13).
struct MapTabView<ViewModel: MapViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    /// YOU-R03: the page is to open at "Over time"; `onHistoryShown` runs once the section is on the page.
    var focusesHistory = false
    var onHistoryShown: () -> Void = {}
    @State private var sharing = false
    /// QUIZ-R04a to R04c: the sheet that says how the map was drawn from the Quiz answers.
    @State private var isExplainingMap = false

    static var historyID: String { "you.map.history" }

    var body: some View {
        if let model = viewModel.uiModel.content {
            YouPanel {
                VStack(alignment: .leading, spacing: 0) {
                    PalateMapChart(values: model.map.chartValues, labels: PalateAxis.allCases.map(\.label),
                                   strong: Set(model.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }))
                        .scaleEffect(0.84)
                        // The scaled size, so the chart's own 330 pt never widens the page.
                        .frame(width: PalateMapChart.size.width * 0.84, height: PalateMapChart.size.height * 0.84)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)

                    SectionTitle(text: viewModel.uiModel.yourReadingsText).padding(.top, 48)
                    VStack(spacing: 0) {
                        ForEach(model.readings) { row in
                            ReadingLine(row: row)
                        }
                    }
                    .padding(.top, 10)

                    if !model.snapshots.isEmpty {
                        // The id takes part of the gap above, so the title lands clear of the scroll's top fade.
                        OverTimeSection(model: model)
                            .padding(.top, 24)
                            .id(Self.historyID)
                            .padding(.top, 36)
                            .onChange(of: focusesHistory, initial: true) {
                                if focusesHistory { onHistoryShown() }
                            }
                    }

                    Button { isExplainingMap = true } label: {
                        HStack(spacing: 10) {
                            SectionTitle(text: viewModel.uiModel.whereTheMapPointsText)
                            Spacer(minLength: 12)
                            InfoMark()
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(viewModel.uiModel.howTheMapIsDrawnText))
                    .padding(.top, 48)
                    Text(model.narrative).font(UVVAFont.sans(14)).lineSpacing(9).opacity(0.86)
                        .padding(.top, 2)

                    ActionButton(viewModel.uiModel.shareMyMapText) { sharing = true }
                        .padding(.top, 40)
                    ActionButton(viewModel.uiModel.redoTheMapText, style: .outline, action: viewModel.redoMap)
                        .padding(.top, 10)
                }
            }
            .sheet(isPresented: $isExplainingMap) {
                InfoSheet(title: viewModel.uiModel.howTheMapIsDrawnText, text: viewModel.uiModel.mapDrawnText)
            }
            .fullScreenCover(isPresented: $sharing) {
                ShareScreen(title: viewModel.uiModel.shareMyMapText, message: viewModel.uiModel.shareMessage) { format in
                    PalateShareCard(heading: viewModel.uiModel.thisIsMyWinePalateText,
                                    phrase: viewModel.uiModel.name,
                                    chartValues: model.map.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                                    strong: Set(model.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                                    lines: [ShareCardLine(tag: viewModel.uiModel.palateText,
                                                          text: model.dominantPhrase)],
                                    format: format)
                } onFinish: {
                    sharing = false
                }
            }
        }
    }
}
